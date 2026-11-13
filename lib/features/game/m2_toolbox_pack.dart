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
import 'm2_toolbox_pack_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 2.1, কাজ 1: "টুলবক্স সাজাও". In the tool store before an LT job:
// the docket on the wall lists the four hand tools the job needs; for each,
// the trainee takes one down from the pegboard (the 1000V mark is readable
// only up close), runs a finger along it (a crack, a cut, a burn mark on the
// handle, a blunt cutter edge, a bent screwdriver tip show only where the hand
// has been — the lesson's daily checks), touches the line tester to a known
// live point (does the neon glow?), then packs it into the open toolbox, sets
// it aside into the বাতিল crate (a decision, like packing), or just puts it
// back on its peg (the same answer for every tool, so putting back never
// tells which one is damaged). On one tool of the four no good one hangs on
// the board: he must send it back for a replacement. Once a play the careless
// coworker (level 1's rival) peeps in: "টেপ মেরে নিলেই চলবে" for a damaged
// handle, or the lesson's own myth "গ্লাভস তো পরাই আছে — সাধারণটাতেই চলবে".
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene, corner guide, ◆ on the table → "কেন …?" → the next tool by itself.
//
// Deadly (lesson: "Non-insulated Pliers LT Line-এ = বিপদ", "সস্তা
// Non-insulated Tool = দামী দুর্ঘটনা", myth: gloves + non-insulated = shock):
// packing a tool without the 1000V insulation for the LT job; taping a
// damaged handle on his word. Slips: packing a damaged insulated tool (it is
// set aside), packing the tester untested, asking for a replacement when a
// good tool was there, setting a sound tool aside (a wrong flag: it goes
// back on the board).
//
// The coworker's line fits the moment (tbPushNow): the tape push only once
// the player's own hand has found the damaged handle (it never names a fault
// he has not seen), the gloves push while the plain tool is still on the
// board. Packing, sending back, or setting aside the tool he would push waits
// for him (holdForCoworker), so a fast play still meets him; nothing on the
// scene takes a touch in a right move's praise window (tableBusy).
// Listening stays deadly: the act he pushes (a plain tool, or a taped damaged
// handle, packed for the LT job) is on this rung's deadly list
// (MODULE2_LADDER.md step 2).
//
// Gesture hints (how, never what): a sweep over the hanging tools and the
// replacement button; in the close look a short generic drag nudge on the
// tool (upward, never along it toward a fault), then a sweep over its
// controls; a tap on the docket held up close.
//
// Voice: the guide's lines on device TTS; the coworker's two pushes are
// silent with the caption held until they are recorded in his voice (his
// exit line is already recorded). Art: the store, the tools and the consequence are drawn
// in code (m2_toolbox_pack_world.dart and the painters below), so marks,
// builds and faults vary each play; the mistake cards use the bundled
// photos in assets/safety/library/tools/.

// ============================================================================
// Content
// ============================================================================

/// The four hand tools of the lesson the job's docket lists.
enum TbKind { pliers, stripper, screwdriver, tester }

extension TbKindText on TbKind {
  String get nameBn => switch (this) {
        TbKind.pliers => 'কম্বিনেশন প্লায়ার্স',
        TbKind.stripper => 'ওয়্যার স্ট্রিপার',
        TbKind.screwdriver => 'স্ক্রুড্রাইভার',
        TbKind.tester => 'লাইন টেস্টার',
      };

  /// The rating printed on the tool (the line tester is an LV indicator).
  String get mark => this == TbKind.tester ? '500V' : '1000V';

  /// 0-based point of lesson 2.1 that teaches this tool.
  int get lessonPoint => switch (this) {
        TbKind.pliers => 0,
        TbKind.stripper => 1,
        TbKind.screwdriver => 2,
        TbKind.tester => 4,
      };
}

enum TbFlaw { none, crack, cut, burn, blunt, bentTip, deadNeon }

/// The faults a strip of tape could be wound over (the handle's insulation).
const tbHandleFlaws = {TbFlaw.crack, TbFlaw.cut, TbFlaw.burn};

@immutable
class TbTool {
  const TbTool({required this.id, required this.kind, this.insulated = true, this.flaw = TbFlaw.none});
  final String id;
  final TbKind kind;

  /// VDE 1000V insulated (marked); false = a plain, unmarked tool.
  final bool insulated;
  final TbFlaw flaw;
  bool get plain => !insulated;
  bool get sound => insulated && flaw == TbFlaw.none;
}

@immutable
class TbRound {
  const TbRound({required this.kind, required this.tools});
  final TbKind kind;
  final List<TbTool> tools;

  /// No good tool of this kind on the board: send for a replacement.
  bool get noneFits => !tools.any((t) => t.sound);
}

@immutable
class TbDocket {
  const TbDocket({required this.jobBn, required this.feederBn, required this.timeBn});
  final String jobBn;
  final String feederBn;
  final String timeBn;
}

/// What the careless coworker pushes.
enum TbPush { tape, gloves }

@immutable
class TbDeal {
  const TbDeal({required this.docket, required this.rounds, required this.callRound, required this.preferTape});
  final TbDocket docket;
  final List<TbRound> rounds;

  /// The tool on which he peeps in (or a later one, if nothing he could push
  /// is still on the board).
  final int callRound;
  final bool preferTape;
}

abstract final class TbLines {
  static const title = 'টুলবক্স সাজাও';
  static const intro = 'এলটি লাইনের কাজ! ডকেট দেখে টুলবক্স সাজান — প্রতিটা টুল হাতে নিয়ে যাচাই করে।';
  static String ask(TbKind k) => '${k.nameBn} — বোর্ডের কোনটা নেবেন?';
  static const inspectAsk = 'হাতলে আঙুল বুলিয়ে মার্ক আর অবস্থা দেখুন। নেবেন?';
  static const testAsk = 'জানা লাইভ পয়েন্টে ছুঁইয়ে দেখুন। নেবেন?';
  static final tasks = [for (final k in TbKind.values) ask(k), inspectAsk, testAsk];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const docket = 'ডকেট';
  static const lineBn = 'এলটি লাইন';
  static const toolsWord = 'টুল:';
  static String shutdown(TbDocket d) => 'শাটডাউন ${d.timeBn}';
  static const toolLabel = 'টুল';
  static const handLabel = 'টুল হাতে';
  static const liveLabel = 'লাইভ পয়েন্ট';
  static const take = 'বাক্সে রাখুন';
  static const putBack = 'ফেরত রাখুন';
  static const aside = 'বাতিল করুন';
  static const hold = 'ভালো একটাও নেই — বদলে আনি';
  static const rejected = 'বাতিল';

  // The reasons (lesson 2.1). Every card set stays within 1.3× in length.
  static const packAsk = 'কেন এই টুলটা বাক্সে রাখলেন?';
  static const holdAsk = 'কেন বদলে আনবেন?';
  static List<String> packRight(TbKind k) => switch (k) {
        TbKind.pliers => const ['হাতলে 1000V মার্ক, ফাটল-কাট-পোড়া নেই', 'VDE 1000V প্লায়ার্স, হাতল পুরো অক্ষত'],
        TbKind.stripper => const ['1000V মার্ক আছে, কাটারের ধারও ঠিক আছে', 'VDE 1000V স্ট্রিপার, খাঁজ আর ধার ঠিক'],
        TbKind.screwdriver => const ['1000V মার্ক, ডগা সোজা, হাতল অক্ষত', 'গোড়া পর্যন্ত ইনসুলেটেড, ডগাও ঠিক আছে'],
        TbKind.tester => const ['জানা লাইভ পয়েন্টে নিয়ন জ্বলে উঠেছে', 'টেস্ট করে দেখেছি, টেস্টার কাজ করছে'],
      };
  static const packMyths = [
    'গ্লাভস পরা থাকলে যেকোনো টুলেই চলে',
    'সস্তা টুলেও তো কাজ একই রকম হয়',
    'হাতলে টেপ জড়ানো থাকলেই নিরাপদ',
    'হাতের কাছে ছিল, তাই এটাই তুলে নিলাম',
    'নতুন দেখতে, তাই খুঁটিয়ে দেখিনি',
    'লাইন তো বন্ধ, টুল যেকোনো হলেই চলে',
    '1000V লেখা আছে, তাই হাতল আর দেখিনি',
  ];
  static const testerMyth = 'এটা দিয়ে নিউট্রালও পরীক্ষা করা যাবে';
  static const testerMythOld = 'কাল টেস্ট করেছিলাম, আজ আর লাগবে না';
  static List<String> packWrong(TbKind k) => [if (k == TbKind.tester) ...[testerMyth, testerMythOld], ...packMyths];

  static const holdRight = [
    'মার্ক আর অবস্থা মেলে এমন টুল নেই',
    'ভালো টুল নেই, তাই স্টোর থেকে বদলে আনি',
  ];
  static const holdWrong = [
    'দেরি হচ্ছে, তাই টুলটা বাদ দিলাম',
    'টুলটা ভারী লাগছিল, তাই নিলাম না',
    'স্টোরকিপার বকবে, তাই কিছু নিইনি',
    'অন্যের টুল দিয়েই কাজটা সেরে নেব',
    'এই টুলটা ছাড়াও কাজটা চলে যাবে',
  ];

  /// The careless coworker. His exit line is already recorded in his voice;
  /// the two pushes go to device TTS until they are recorded.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerTape = CoworkerScript(
    line: 'আরে! হাতলে একটু খুঁত — টেপ মেরে নিলেই চলবে!',
    exitLine: coworkerExit,
    right: ['না — হাতল নষ্ট, এই টুল বাতিল করব', 'টেপে ইনসুলেশন ফেরে না, বদলে আনব', 'ইনসুলেশন নষ্ট হলে ওই টুল নেব না'],
    wrong: [
      'ঠিক, টেপ জড়িয়ে নিলেই হবে',
      'একটু খুঁতে কিছু হয় না, নিই',
      'টেপ মেরে আজকের কাজটা সারি',
      'নতুন আনতে দেরি, এটাই চলুক',
      'সবাই তো টেপ মেরেই চালিয়ে নেয়',
    ],
    asks: ['ও বলছে টেপ মারলেই চলবে। আপনি কী করবেন?', 'টেপ মেরে নেবেন, না বদলে আনবেন?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static const coworkerGloves = CoworkerScript(
    line: 'গ্লাভস তো পরাই আছে — মার্ক-টার্ক ছাড়া সাধারণটাতেই চলবে!',
    exitLine: coworkerExit,
    right: ['না — গ্লাভস আর 1000V দুটোই চাই', 'মার্ক ছাড়া সাধারণ টুল নেব না', 'এক স্তর ফেল করলেই শক — নেব না'],
    wrong: [
      'ঠিক, গ্লাভস থাকলে সাধারণটাই চলে',
      'সস্তা টুলেও তো কাজ হয়ে যায়',
      'মার্ক-টার্ক দেখার সময় নেই এখন',
      'গ্লাভস তো আছে, যেকোনোটা নিই',
      'সবাই তো সাধারণটা দিয়েই সারে',
    ],
    asks: ['ও বলছে গ্লাভস থাকলেই চলবে। আপনি কী করবেন?', 'সাধারণ টুল নেবেন, না 1000V?', 'কার কথা শুনবেন — ওর, না নিয়মের?'],
  );
  static CoworkerScript coworker(TbPush p) => p == TbPush.tape ? coworkerTape : coworkerGloves;

  static const callHeld = 'ঠিক! গ্লাভস আর 1000V টুল — দুই স্তরই চাই।';
  static const callHeldTape = 'ঠিক! টেপে ইনসুলেশন ফেরে না — নষ্ট হাতলের টুল বাতিল।';
  static const asideFlaw = 'ঠিক — ভাঙা টুল বাতিল।';
  static const asidePlain = 'ঠিক — মার্ক ছাড়া টুল বাতিল।';
  static const lit = 'নিয়ন জ্বলছে।';
  static const dark = 'নিয়ন জ্বলল না!';
  static const holdDone = 'ঠিক! ভাঙা টুল নয় — স্টোর থেকে ভালোটা আসবে।';
  static const allSet = 'টুলবক্স তৈরি! মার্ক আর অবস্থা — দুটোই দেখেছেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — প্রতিটা টুলের মার্ক আর অবস্থা দেখুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';
  static const caughtMark = '1000V মার্ক দেখে টুল নিয়েছেন';
  static const caughtTest = 'জানা লাইভ পয়েন্টে টেস্টার যাচাই';
  static const caughtHold = 'ভালো টুল না পেয়ে বদলে আনা';
  static const caughtFlaw = 'ভাঙা টুল বাতিল';
  static const caughtPlain = 'মার্ক ছাড়া টুল বাতিল';
  static const caughtCall = 'চাপে “না” বলেছেন';
  static const jobs = ['সার্ভিস তার বদল', 'মিটার বোর্ডের তার জোড়া', 'এলটি জাম্পার মেরামত'];
  static const feeders = ['রামপুর ফিডার', 'হাটখোলা ফিডার', 'নদীপাড় ফিডার', 'স্টেশন রোড ফিডার', 'কলেজপাড়া ফিডার'];
  static const times = ['10:00–14:00', '09:30–13:00', '11:00–15:30', '08:00–12:00'];
}

abstract final class TbMistakes {
  static const _pliersArt = 'assets/safety/library/tools/Combination_Pliers.webp';
  static const _setArt = 'assets/safety/library/tools/Insulated_Hand_Tools_Set.webp';
  static const _driverArt = 'assets/safety/library/tools/Insulated_Screwdriver.webp';

  static String _art(TbKind k) => switch (k) {
        TbKind.pliers => _pliersArt,
        TbKind.screwdriver => _driverArt,
        _ => _setArt,
      };

  /// A plain tool (no 1000V insulation) packed for the LT job.
  /// Every card this level can book, for the mistakes book (`knownMistakes`).
  static List<DoMistake> get all => [
        for (final k in TbKind.values) ...[
          noMark(k),
          tape(k),
          asideSound(k),
          for (final f in const [TbFlaw.crack, TbFlaw.cut, TbFlaw.burn]) handle(k, f),
        ],
        blunt,
        bentTip,
        deadNeon,
        untested,
        heldWhenRight,
      ];

  static DoMistake noMark(TbKind k) => DoMistake(
        key: '2.1/toolbox/no-mark/${k.name}',
        textBn: 'হাতলে 1000V মার্ক নেই — সাধারণ টুল এলটি লাইনে বিপদ। গ্লাভস থাকলেও নয়: যেকোনো একটা ফেল করলেই শক, তাই গ্লাভস + VDE 1000V টুল।',
        art: _art(k),
        deadly: true,
        lessonPoint: k.lessonPoint,
      );
  static DoMistake tape(TbKind k) => DoMistake(
        key: '2.1/toolbox/tape/${k.name}',
        textBn: 'হাতলে ফাটল, কাট বা পোড়া দাগ — ইনসুলেশন ঠিক না থাকলে ব্যবহার নয়। টেপ জড়ালেও সেই হাতল আর পরীক্ষিত 1000V নয়: টুল বাতিল, স্টোর থেকে বদলে নিন।',
        art: _art(k),
        deadly: true,
        lessonPoint: k.lessonPoint,
      );
  /// A sound tool set aside (a wrong flag): it goes back on the board.
  static DoMistake asideSound(TbKind k) => DoMistake(
        key: '2.1/toolbox/aside-sound/${k.name}',
        textBn: k == TbKind.tester
            ? 'টেস্টারটা ভালোই ছিল — বাতিলের আগে জানা লাইভ পয়েন্টে ছুঁইয়ে দেখুন নিয়ন জ্বলে কিনা।'
            : 'টুলটা ভালোই ছিল — বাতিলের আগে হাতলে আঙুল বুলিয়ে 1000V মার্ক আর অবস্থা দেখে নিন।',
        art: _art(k),
        lessonPoint: k.lessonPoint,
      );
  static DoMistake handle(TbKind k, TbFlaw f) => DoMistake(
        key: '2.1/toolbox/${f.name}/${k.name}',
        textBn: '${switch (f) {
          TbFlaw.crack => 'হাতলের ইনসুলেশনে ফাটল',
          TbFlaw.cut => 'হাতলের ইনসুলেশন কাটা',
          _ => 'হাতলে পোড়া দাগ',
        }} — ইনসুলেশন ঠিক না থাকলে ব্যবহার নয়। প্রতিদিন হাতলে ফাটল, কাট, পোড়া দাগ দেখুন।',
        art: _art(k),
        lessonPoint: k.lessonPoint,
      );
  static const blunt = DoMistake(
    key: '2.1/toolbox/blunt-cutter',
    textBn: 'কাটারের ধার ভোঁতা — ভোঁতা কাটার ব্যবহার করবেন না। কাজের আগে কাটারের ধার আর স্ট্রিপারের খাঁজ দেখে নিন।',
    art: _setArt,
    lessonPoint: 1,
  );
  static const bentTip = DoMistake(
    key: '2.1/toolbox/bent-tip',
    textBn: 'স্ক্রুড্রাইভারের ডগা বাঁকা — স্ক্রু হেড নষ্ট হয়, হাত পিছলে শর্ট সার্কিট বা আঘাত হতে পারে। ডগা বাঁকা বা ভাঙা হলে বাতিল।',
    art: _driverArt,
    lessonPoint: 2,
  );
  static const deadNeon = DoMistake(
    key: '2.1/toolbox/dead-neon',
    textBn: 'জানা লাইভ পয়েন্টেও নিয়ন জ্বলেনি — এমন টেস্টারে ভরসা নয়। কাজের আগে জানা লাইভ পয়েন্টে টেস্ট করে নিন।',
    art: _setArt,
    lessonPoint: 4,
  );
  static const untested = DoMistake(
    key: '2.1/toolbox/untested',
    textBn: 'টেস্টার যাচাই না করেই বাক্সে — জানা লাইভ পয়েন্টে নিয়ন জ্বলে কিনা আগে দেখে নিন।',
    art: _setArt,
    lessonPoint: 4,
  );
  static const heldWhenRight = DoMistake(
    key: '2.1/toolbox/held-when-right',
    textBn: 'ভালো টুলটা বোর্ডেই ছিল — 1000V মার্ক আর অবস্থা ভালো করে দেখুন।',
    art: _setArt,
    lessonPoint: 0,
  );

  static DoMistake forFlaw(TbTool t) => switch (t.flaw) {
        TbFlaw.blunt => blunt,
        TbFlaw.bentTip => bentTip,
        TbFlaw.deadNeon => deadNeon,
        final f => handle(t.kind, f),
      };
}

/// The faults each kind of tool can have on this board.
List<TbFlaw> tbFlawsOf(TbKind k) => switch (k) {
      TbKind.pliers => const [TbFlaw.crack, TbFlaw.cut, TbFlaw.burn],
      TbKind.stripper => const [TbFlaw.blunt, TbFlaw.crack],
      TbKind.screwdriver => const [TbFlaw.bentTip, TbFlaw.crack],
      TbKind.tester => const [TbFlaw.deadNeon],
    };

/// A fresh board each play: the job, the order of the tools, which one has
/// no good tool, the faults, the board order and the coworker's moment vary.
TbDeal dealToolbox(math.Random rng) {
  var n = 0;
  TbTool tool(TbKind k, {bool insulated = true, TbFlaw f = TbFlaw.none}) => TbTool(id: 'tool${n++}', kind: k, insulated: insulated, flaw: f);
  TbFlaw anyFlaw(TbKind k) {
    final fs = tbFlawsOf(k);
    return fs[rng.nextInt(fs.length)];
  }

  final later = [TbKind.stripper, TbKind.screwdriver, TbKind.tester]..shuffle(rng);
  final kinds = [TbKind.pliers, ...later];
  // One of the stripper / screwdriver has no good tool on the board.
  final hold = rng.nextBool() ? TbKind.stripper : TbKind.screwdriver;
  final rounds = <TbRound>[];
  for (final k in kinds) {
    final List<TbTool> tools;
    if (k == TbKind.tester) {
      tools = [tool(k), tool(k, f: TbFlaw.deadNeon), if (rng.nextBool()) tool(k, f: TbFlaw.deadNeon)];
    } else if (k == hold) {
      tools = [for (final f in tbFlawsOf(k)) tool(k, f: f), tool(k, insulated: false)];
    } else {
      tools = [tool(k), tool(k, f: anyFlaw(k)), tool(k, insulated: false)];
    }
    tools.shuffle(rng);
    rounds.add(TbRound(kind: k, tools: tools));
  }
  final callable = [for (var i = 0; i < rounds.length; i++) if (rounds[i].kind != TbKind.tester) i];
  return TbDeal(
    docket: TbDocket(
      jobBn: TbLines.jobs[rng.nextInt(TbLines.jobs.length)],
      feederBn: TbLines.feeders[rng.nextInt(TbLines.feeders.length)],
      timeBn: TbLines.times[rng.nextInt(TbLines.times.length)],
    ),
    rounds: rounds,
    callRound: callable[rng.nextInt(callable.length)],
    preferTape: rng.nextBool(),
  );
}

/// What the careless coworker can push on round [r] now — only a tool still
/// on the board: tape on an insulated tool with a damaged handle, or the
/// plain one ("গ্লাভস তো আছে"). The dealt push first, else the other; null
/// when neither is there.
TbPush? tbPushFor(TbRound r, Set<String> rejected, {required bool preferTape}) {
  final tape = r.tools.any((t) => t.insulated && tbHandleFlaws.contains(t.flaw) && !rejected.contains(t.id));
  final gloves = r.tools.any((t) => t.plain && !rejected.contains(t.id));
  if (preferTape && tape) return TbPush.tape;
  if (gloves) return TbPush.gloves;
  return tape ? TbPush.tape : null;
}

/// What the careless coworker can push right now, so his line fits the
/// moment: the tape push only for an insulated tool with a damaged handle
/// that is in the player's hand and whose fault the player has found
/// ([held], [spotted]) — he never names a fault the player has not seen; the
/// gloves push while the round's plain tool is still on the board or in hand.
/// [preferTape] (the dealt push) waits for the tape moment while a damaged
/// handle still hangs on the board, unless [forced] (a decisive control is
/// waiting for him). Null: nothing he could push fits now.
TbPush? tbPushNow(
  TbRound r, {
  required TbTool? held,
  required Set<String> rejected,
  required Set<String> spotted,
  required bool preferTape,
  bool forced = false,
}) {
  bool handle(TbTool t) => t.insulated && tbHandleFlaws.contains(t.flaw);
  final plainLeft = r.tools.any((t) => t.plain && !rejected.contains(t.id));
  final tapeNow = held != null && handle(held) && spotted.contains(held.id) && !rejected.contains(held.id);
  if (tapeNow && (preferTape || !plainLeft)) return TbPush.tape;
  if (preferTape && !forced && r.tools.any((t) => handle(t) && !rejected.contains(t.id))) return null;
  if (plainLeft) return TbPush.gloves;
  return tapeNow ? TbPush.tape : null;
}

/// The tool he pushes on round [r].
TbTool? tbPushedTool(TbRound r, TbPush p, Set<String> rejected) {
  for (final t in r.tools) {
    if (rejected.contains(t.id)) continue;
    if (p == TbPush.tape ? (t.insulated && tbHandleFlaws.contains(t.flaw)) : t.plain) return t;
  }
  return null;
}

enum TbVerdict { right, slip, deadly }

@immutable
class TbOutcome {
  const TbOutcome(this.verdict, {this.mistake});
  final TbVerdict verdict;
  final DoMistake? mistake;
}

/// The play state (pure logic).
class TbRun {
  TbRun(this.deal);
  final TbDeal deal;
  int round = 0;
  int slips = 0;
  DoMistake? deadly;

  /// This tool is decided (packed, or sent back for a replacement): the
  /// reason comes, then [next].
  bool shown = false;

  /// Tools set aside on this round (in the বাতিল crate).
  final Set<String> rejected = {};

  /// Tools on this round whose fault the player has seen (by hand, by the
  /// live-point test, or on the card after packing it).
  final Set<String> spotted = {};

  /// Testers touched to the known live point on this round.
  final Set<String> tested = {};

  /// What is in the toolbox: compartment (round) → tool; a round sent back
  /// for a replacement stays empty.
  final Map<int, TbTool> packed = {};
  final List<String> caught = [];

  bool get done => round >= deal.rounds.length;
  bool get ended => done || deadly != null;
  TbRound get current => deal.rounds[round.clamp(0, deal.rounds.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Packs [t] into the toolbox.
  TbOutcome pack(TbTool t) {
    if (ended || shown || rejected.contains(t.id)) return const TbOutcome(TbVerdict.slip);
    if (t.plain) return _deadly(TbMistakes.noMark(t.kind));
    if (t.flaw != TbFlaw.none) {
      slips++;
      rejected.add(t.id);
      spotted.add(t.id);
      return TbOutcome(TbVerdict.slip, mistake: TbMistakes.forFlaw(t));
    }
    if (t.kind == TbKind.tester && !tested.contains(t.id)) {
      // A good tester, but untried: it goes back on the board.
      slips++;
      return const TbOutcome(TbVerdict.slip, mistake: TbMistakes.untested);
    }
    _tag(t.kind == TbKind.tester ? TbLines.caughtTest : TbLines.caughtMark);
    packed[round] = t;
    shown = true;
    return const TbOutcome(TbVerdict.right);
  }

  /// The player's hand found [t]'s fault in the close look.
  void spot(TbTool t) {
    if (t.flaw != TbFlaw.none && t.flaw != TbFlaw.deadNeon) spotted.add(t.id);
  }

  /// Touches tester [t] to the known live point; true = the neon glows.
  bool test(TbTool t) {
    if (t.kind != TbKind.tester) return false;
    tested.add(t.id);
    if (t.flaw == TbFlaw.deadNeon) {
      spotted.add(t.id);
      return false;
    }
    return true;
  }

  /// Sets [t] aside into the বাতিল crate — a decision, like packing: a plain
  /// tool or a damaged one goes in (right); a sound tool is a wrong flag (a
  /// slip) and goes back on the board. (Putting a tool back on its peg is
  /// no act at all here: it changes nothing and tells nothing.)
  TbOutcome setAside(TbTool t) {
    if (ended || shown || rejected.contains(t.id)) return const TbOutcome(TbVerdict.slip);
    if (t.sound) {
      slips++;
      return TbOutcome(TbVerdict.slip, mistake: TbMistakes.asideSound(t.kind));
    }
    rejected.add(t.id);
    _tag(t.plain ? TbLines.caughtPlain : TbLines.caughtFlaw);
    return const TbOutcome(TbVerdict.right);
  }

  /// "ভালো একটাও নেই — বদলে আনি".
  TbOutcome holdJob() {
    if (ended || shown) return const TbOutcome(TbVerdict.slip);
    if (!current.noneFits) {
      slips++;
      return const TbOutcome(TbVerdict.slip, mistake: TbMistakes.heldWhenRight);
    }
    _tag(TbLines.caughtHold);
    shown = true;
    return const TbOutcome(TbVerdict.right);
  }

  /// The next tool (after the reason).
  void next() {
    round++;
    rejected.clear();
    spotted.clear();
    tested.clear();
    shown = false;
  }

  TbOutcome _deadly(DoMistake m) {
    deadly = m;
    return TbOutcome(TbVerdict.deadly, mistake: m);
  }
}

@immutable
class M2ToolboxPack {
  const M2ToolboxPack({required this.id, required this.titleBn, this.quickMs = 90000});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m2ToolboxPack21 = M2ToolboxPack(id: 'do_2_1_a', titleBn: TbLines.title);
const Map<String, M2ToolboxPack> m2ToolboxPacks = {'do_2_1_a': m2ToolboxPack21};

// ============================================================================
// Page
// ============================================================================

class M2ToolboxPage extends StatefulWidget {
  const M2ToolboxPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M2ToolboxPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M2ToolboxPage> createState() => _M2ToolboxPageState();
}

class _M2ToolboxPageState extends State<M2ToolboxPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TbRunPage(
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

class _TbRunPage extends ConsumerStatefulWidget {
  const _TbRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M2ToolboxPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TbRunPage> createState() => _TbRunPageState();
}

class _TbRunPageState extends ConsumerState<_TbRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final TbRun _run = TbRun(dealToolbox(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;

  /// The tool in the trainee's hands (the close look).
  TbTool? _held;
  var _docketOpen = false;
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
  TbPush _push = TbPush.gloves;

  LinemanMode _mode = LinemanMode.idle;
  int _wake = 0;

  /// A deadly move: the store freezes grey, the consequence plays in colour.
  var _freeze = false;
  TbTool? _flashTool;
  var _flashTaped = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how to touch, never what).
  final _hints = IdleHintController();
  final Map<String, GlobalKey> _toolKeys = {};
  final _holdKey = GlobalKey();
  final _closeKey = GlobalKey();
  final _liveKey = GlobalKey();
  final _backKey = GlobalKey();
  final _asideKey = GlobalKey();
  final _takeKey = GlobalKey();
  final _docketZoomKey = GlobalKey();

  /// The hand has slid along the tool in the close look.
  var _slid = false;

  GlobalKey _toolKey(String id) => _toolKeys.putIfAbsent(id, GlobalKey.new);

  @override
  LevelContext get deathCtx => widget.ctx;
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

  String get _ask => TbLines.ask(_run.current.kind);
  String get _task {
    final h = _held;
    if (h == null) return _ask;
    return h.kind == TbKind.tester ? TbLines.testAsk : TbLines.inspectAsk;
  }

  // ---- flow -----------------------------------------------------------------------

  Future<void> _start() async {
    _clock.start();
    _armCoworker();
    await _sayChain([_ask]);
  }

  void _armCoworker() {
    if (!coworkerDone && _run.round >= _run.deal.callRound) scheduleCoworker();
  }

  /// No scene control works now: also never in a right move's praise window
  /// (`tableBusy`: its ◆ wait on the table).
  bool get _blocked => _intro || _busy || _ended || _card != null || reasonOpen || tableBusy || _run.shown || _freeze;

  void _setMode(LinemanMode m) {
    _mode = m;
    _wake++;
  }

  bool _isPushed(TbTool t) => _push == TbPush.tape ? (t.insulated && tbHandleFlaws.contains(t.flaw)) : t.plain;

  /// What he can push now (see [tbPushNow]).
  TbPush? _pushNow({bool forced = false}) => tbPushNow(
        _run.current,
        held: _held,
        rejected: _run.rejected,
        spotted: _run.spotted,
        preferTape: _run.deal.preferTape,
        forced: forced,
      );

  /// A decisive control (pack, send back, set aside): while he is
  /// due and something he could push is still there, it waits for him.
  bool _holdFor() {
    if (!coworkerDue) return false;
    final p = _pushNow(forced: true);
    if (p == null) return false;
    _push = p;
    return holdForCoworker();
  }

  /// A tool comes off the pegboard into the trainee's hands.
  void _pick(TbTool t, Offset origin) {
    // While he talks the board waits: only the deck answers him (a tap on a
    // tool never skips him or counts as refusing him).
    if (_blocked || coworkerOpen || _held != null || _docketOpen || _run.rejected.contains(t.id)) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/impact_metal.ogg', volume: 0.4, muted: false));
    _hush();
    setState(() {
      _held = t;
      _slid = false;
      _setMode(LinemanMode.hold);
    });
    unawaited(_sayChain([_task]));
  }

  /// A fault came into view under the hand. No sound or buzz: the eye must
  /// see it (a cue only on faults would find them for the player).
  void _found() {
    final t = _held;
    if (t != null) _run.spot(t);
  }

  /// The hand first touched the tool in the close look.
  void _touched() {
    if (!_slid && mounted) setState(() => _slid = true);
  }

  /// The tester's tip on the known live point (null: no touch taken now).
  bool? _test() {
    final t = _held;
    if (t == null || _blocked || coworkerOpen) return null;
    final lit = _run.test(t);
    HapticFeedback.mediumImpact();
    if (!_muted) unawaited(ZlFx.cue(lit ? 'sounds/intro/click.ogg' : 'sounds/learn/tock.wav', volume: 0.6, muted: false));
    unawaited(_sayChain([lit ? TbLines.lit : TbLines.dark]));
    return lit;
  }

  /// Back on its peg: the same sound and the same line for every tool, so
  /// putting back never tells which one is damaged (no decision, no cost).
  void _putBack() {
    if (_held == null || _blocked || coworkerOpen) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.4, muted: false));
    setState(() {
      _held = null;
      _setMode(LinemanMode.idle);
    });
    unawaited(_sayChain([_ask]));
  }

  /// Into the বাতিল crate — a decision: a sound tool set aside is a wrong
  /// flag (a slip card; it goes back on the board).
  void _aside(Offset origin) {
    final t = _held;
    if (t == null || _blocked || coworkerOpen) return;
    if (_holdFor()) return;
    final o = _run.setAside(t);
    final right = o.verdict == TbVerdict.right;
    setState(() {
      _held = null;
      _setMode(right ? LinemanMode.idle : LinemanMode.worried);
    });
    if (right) {
      HapticFeedback.selectionClick();
      if (!_muted) unawaited(ZlFx.cue('sounds/learn/tag_slap.wav', volume: 0.6, muted: false));
      unawaited(_sayChain([t.plain ? TbLines.asidePlain : TbLines.asideFlaw, _ask], mood: GuideMood.glad));
      return;
    }
    final m = o.mistake;
    if (m != null) unawaited(_slip(m, origin));
  }

  void _pack(Offset origin) {
    final t = _held;
    if (t == null || _blocked || coworkerOpen) return;
    if (_holdFor()) return;
    setState(() => _held = null);
    final o = _run.pack(t);
    switch (o.verdict) {
      case TbVerdict.right:
        HapticFeedback.lightImpact();
        if (!_muted) {
          unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
          unawaited(ZlFx.cue('sounds/intro/drop.ogg', volume: 0.5, muted: false));
        }
        setState(() => _setMode(LinemanMode.cheer));
        final k = t.kind;
        _askWhy(15, () => dealChoices(TbLines.packRight(k), TbLines.packWrong(k), widget.rng), TbLines.packAsk);
      case TbVerdict.slip:
        setState(() => _setMode(LinemanMode.worried));
        final m = o.mistake;
        if (m != null) unawaited(_slip(m, origin));
      case TbVerdict.deadly:
        unawaited(_deadly(o.mistake!, t));
    }
  }

  void _holdJob(Offset origin) {
    if (_blocked || coworkerOpen || _held != null || _docketOpen) return;
    if (_holdFor()) return;
    _hush();
    final o = _run.holdJob();
    if (o.verdict == TbVerdict.right) {
      HapticFeedback.mediumImpact();
      if (!_muted) unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.6, muted: false));
      setState(() => _setMode(LinemanMode.cheer));
      _askWhy(20, () => dealChoices(TbLines.holdRight, TbLines.holdWrong, widget.rng), TbLines.holdAsk);
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
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: false));
    _armCoworker();
    unawaited(_sayChain([if (held) TbLines.holdDone, _ask]));
  }

  void _openDocket() {
    if (_blocked || coworkerOpen || _held != null) return;
    HapticFeedback.selectionClick();
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: false));
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
  CoworkerScript get coworkerScript => TbLines.coworker(_push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.done || _run.round < _run.deal.callRound) return null;
    // Never in a praise window (_blocked has tableBusy) or over the docket.
    if (_blocked || _docketOpen) return false;
    // His line fits the moment; a decisive control waiting for him
    // (coworkerHeld) takes what fits now. Nothing here: a later tool.
    final push = _pushNow(forced: coworkerHeld);
    if (push == null) return false;
    _push = push;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final r = _run.current;
      final h = _held;
      final t = (h != null && _isPushed(h) ? h : null) ?? tbPushedTool(r, _push, _run.rejected) ?? r.tools.first;
      final m = _push == TbPush.tape ? TbMistakes.tape(r.kind) : TbMistakes.noMark(r.kind);
      _run.deadly = m;
      await _deadly(m, t, taped: _push == TbPush.tape);
      return;
    }
    _run.caught.add(TbLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    if (direct) return;
    final chain = _chain;
    unawaited(() async {
      await coworkerSnarl();
      if (!mounted || chain != _chain) return;
      await _sayChain([_push == TbPush.tape ? TbLines.callHeldTape : TbLines.callHeld, _task], mood: GuideMood.glad);
    }());
  }

  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? TbLines.tapWhy[_nudgeN++ % TbLines.tapWhy.length]
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
    if (!_muted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
    _hush();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
    });
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('toolbox/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  Future<void> _deadly(DoMistake m, TbTool tool, {bool taped = false}) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    HapticFeedback.heavyImpact();
    if (!_muted) unawaited(ZlFx.cue('sounds/learn/spark.wav', volume: 0.9, muted: false));
    final frozen = _frozen = Completer<void>();
    setState(() {
      _held = null;
      _docketOpen = false;
      _flashTool = tool;
      _flashTaped = taped;
      _setMode(LinemanMode.worried);
      _freeze = true;
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
    final speak = await SpokenOnce.first('toolbox/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? TbLines.deadlyWord : TbLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() {
          _card = null;
          _setMode(LinemanMode.idle);
        });
        unawaited(_sayChain([_ask]));
      case MistakeTone.nearMiss:
        _hush();
        widget.onRetry(_muted);
      case MistakeTone.deadly:
        _popped = true;
        unawaited(dieAndLeave());
    }
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
    await _say(!_run.passed ? TbLines.fail : (_quickBonus ? TbLines.quick : TbLines.allSet),
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

  // ---- gesture hints (how to touch, never what) ------------------------------------

  /// The level waits for a touch on the scene: not during the intro, a card,
  /// a deck, the praise window, the coworker, the freeze or the result.
  bool get _hintWaiting => !_blocked && _card == null && !coworkerOnScreen && !struckOut && _mark == null;

  Object get _hintKey => '${_run.round}/${_held?.id}/$_slid/$_docketOpen/${_run.rejected.length}/${_run.tested.length}/${_run.slips}';

  /// The docket held up close: tap it to hang it back (the one way on). In
  /// the close look: before the hand has touched the tool, a short slide
  /// nudge on it (the kit's generic upward drag, never along the tool toward
  /// a fault); then a sweep over every control (the live point while the
  /// tester is untried, put back, set aside, pack). On the board: a sweep over every hanging tool and the
  /// replacement button.
  HintSpec? _hint() {
    if (_docketOpen) return HintSpec.tapOn(_docketZoomKey);
    final h = _held;
    if (h != null) {
      if (!_slid) return HintSpec.dragFrom(_closeKey);
      return HintSpec.sweepOver([if (h.kind == TbKind.tester && !_run.tested.contains(h.id)) _liveKey, _backKey, _asideKey, _takeKey]);
    }
    final r = _run.current;
    return HintSpec.sweepOver([
      for (final t in r.tools)
        if (!_run.rejected.contains(t.id) && _run.packed[_run.round]?.id != t.id) _toolKey(t.id),
      _holdKey,
    ]);
  }

  /// A tap on nothing (the store's wall, the dim round the close look).
  void _missTap() {
    if (_hintWaiting) _hints.missTap();
  }

  // ---- build ------------------------------------------------------------------------

  List<Widget> _layers(BuildContext context, SceneMetrics m, bool quiet) {
    final geo = ToolStoreGeo(m.height);
    final r = _run.current;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final aside = [for (final x in r.tools) if (_run.rejected.contains(x.id)) x];
    final canPick = !_blocked && _held == null && !_docketOpen;
    final done = {for (var i = 0; i < _run.round; i++) i};
    return [
      Positioned.fill(
        key: const ValueKey('store'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (_) => _missTap(),
          child: ColorFiltered(colorFilter: grey, child: RepaintBoundary(child: CustomPaint(painter: ToolStorePainter(geo)))),
        ),
      ),
      Positioned.fromRect(
        key: const ValueKey('docket'),
        rect: geo.docket,
        child: ColorFiltered(
          colorFilter: grey,
          child: _DocketSheet(deal: _run.deal, done: done, quiet: quiet, onTap: _openDocket),
        ),
      ),
      // What is packed lies in its compartment.
      for (final e in _run.packed.entries)
        Positioned.fromRect(
          key: ValueKey('packed-${e.value.id}'),
          rect: geo.compartment(e.key).deflate(3),
          child: ColorFiltered(colorFilter: grey, child: _Packed(tool: e.value, quiet: quiet)),
        ),
      // The pegboard: one hanging place per tool (it stays, empty, once taken).
      for (var i = 0; i < r.tools.length; i++)
        Positioned.fromRect(
          key: ValueKey('slot-${_run.round}-$i'),
          rect: geo.slot(i, r.tools.length),
          child: ColorFiltered(
            colorFilter: grey,
            child: DoDealIn(
              index: i,
              quiet: quiet,
              muted: true,
              child: _BoardTool(
                key: _toolKey(r.tools[i].id),
                tool: r.tools[i],
                gone: _run.rejected.contains(r.tools[i].id) || _run.packed[_run.round]?.id == r.tools[i].id || _held?.id == r.tools[i].id,
                enabled: canPick,
                onTake: (at) => _pick(r.tools[i], at),
              ),
            ),
          ),
        ),
      for (var i = 0; i < aside.length && i < 3; i++)
        Positioned.fromRect(
          key: ValueKey('aside-${aside[i].id}'),
          rect: geo.aside(i),
          child: ColorFiltered(colorFilter: grey, child: _AsideTool(tool: aside[i], index: i, quiet: quiet)),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: geo.trainee,
        child: ColorFiltered(
          colorFilter: grey,
          child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final holdUp = playing && _held == null && !_docketOpen && _card == null && !deckUp && !_run.shown && !coworkerOpen;
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
              labels: [for (final r in _run.deal.rounds) r.kind.nameBn],
              done: {for (var i = 0; i < math.min(_run.round, _run.deal.rounds.length); i++) i},
              current: _run.done ? null : _run.round,
              quiet: quiet,
            ),
            layers: (context, m) => _layers(context, m, quiet),
            hint: _hint,
            hintWaiting: playing && !deckUp && _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 112), quiet: quiet),
              if (holdUp)
                Positioned(
                  key: const ValueKey('hud-hold'),
                  left: 12,
                  right: 128,
                  bottom: pad.bottom + 18,
                  child: KeyedSubtree(key: _holdKey, child: _HoldButton(onTapUp: (d) => _holdJob(d.globalPosition))),
                ),
              if (held != null && playing)
                _Inspect(
                  key: ValueKey('inspect-${held.id}'),
                  tool: held,
                  deal: _run.deal,
                  quiet: quiet,
                  // While he talks the tool stays in hand; the deck answers him.
                  enabled: !coworkerOpen,
                  keys: (close: _closeKey, live: _liveKey, back: _backKey, aside: _asideKey, take: _takeKey),
                  onFound: _found,
                  onTouched: _touched,
                  onMiss: _missTap,
                  onTest: _test,
                  onTake: _pack,
                  onPutBack: _putBack,
                  onAside: _aside,
                ),
              if (_docketOpen && playing)
                _DocketZoom(
                  key: const ValueKey('docket-zoom'),
                  cardKey: _docketZoomKey,
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
                  sound: FailSound.paper,
                  muted: _muted,
                  onRetry: () => widget.onRetry(_muted),
                  onLeave: () => _popOnce(false),
                ),
              if (_freeze && _card == null && _flashTool != null)
                FreezeFrame(
                  key: const ValueKey('freeze'),
                  muted: _muted,
                  ms: quiet ? 300 : 2200,
                  consequence: _ToolFlash(tool: _flashTool!, taped: _flashTaped, quiet: quiet),
                  onDone: () {
                    final f = _frozen;
                    if (f != null && !f.isCompleted) f.complete();
                  },
                ),
              if (_intro)
                GuideIntro(
                  key: const ValueKey('intro'),
                  line: TbLines.intro,
                  alarm: 'sounds/van_arrive.wav',
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

/// The docket on its nail: the job and the four tools, the packed ones ticked.
class _DocketSheet extends StatelessWidget {
  const _DocketSheet({required this.deal, required this.done, required this.quiet, required this.onTap});
  final TbDeal deal;
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
              Text(TbLines.docket, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: _brown, height: 1.1)),
              Container(height: 0.8, color: const Color(0x55B59B62), margin: const EdgeInsets.symmetric(vertical: 2)),
              Text(TbLines.lineBn, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w900, color: _ink, height: 1.15)),
              Text(deal.docket.jobBn, maxLines: 2, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w700, color: _grey, height: 1.2)),
              const SizedBox(height: 3),
              Text(TbLines.toolsWord, style: bangla(fontSize: 6.5, fontWeight: FontWeight.w800, color: _brown, height: 1.1)),
              for (var i = 0; i < deal.rounds.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: Row(
                    children: [
                      Icon(done.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 8, color: done.contains(i) ? const Color(0xFF2E7D32) : _grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(deal.rounds[i].kind.nameBn,
                            maxLines: 1, overflow: TextOverflow.clip, style: bangla(fontSize: 6, fontWeight: FontWeight.w700, color: _ink, height: 1.15)),
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
  final TbDeal deal;
  final Set<int> done;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final d = deal.docket;
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
                width: 290,
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
                        Text(TbLines.docket, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
                      ],
                    ),
                    const Divider(color: Color(0x55B59B62), height: 14),
                    Text('${TbLines.lineBn} · ${d.jobBn}', style: bangla(fontSize: 17, fontWeight: FontWeight.w900, color: _ink, height: 1.3)),
                    Text('${d.feederBn} · ${TbLines.shutdown(d)}', style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: _grey, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(TbLines.toolsWord, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: _brown)),
                    for (var i = 0; i < deal.rounds.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(done.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 20, color: done.contains(i) ? const Color(0xFF2E7D32) : _grey),
                            const SizedBox(width: 8),
                            Flexible(child: Text(deal.rounds[i].kind.nameBn, style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: _ink))),
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

/// A tool hanging on the pegboard, head up. From a step away its mark is a
/// blank white tag and its faults do not show. Tap it, or pull it down, to
/// take it in hand.
class _BoardTool extends StatefulWidget {
  const _BoardTool({super.key, required this.tool, required this.gone, required this.enabled, required this.onTake});
  final TbTool tool;
  final bool gone;
  final bool enabled;
  final ValueChanged<Offset> onTake;

  @override
  State<_BoardTool> createState() => _BoardToolState();
}

class _BoardToolState extends State<_BoardTool> {
  double _pull = 0;
  Offset _at = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    if (widget.gone) return Semantics(label: TbLines.toolLabel, child: const SizedBox.expand());
    return Semantics(
      button: true,
      label: TbLines.toolLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.enabled ? (d) => widget.onTake(d.globalPosition) : null,
        onVerticalDragStart: widget.enabled ? (d) => _at = d.globalPosition : null,
        onVerticalDragUpdate: widget.enabled
            ? (d) {
                _at = d.globalPosition;
                setState(() => _pull = (_pull + d.delta.dy).clamp(0.0, 60.0));
              }
            : null,
        onVerticalDragEnd: widget.enabled
            ? (_) {
                final out = _pull > 24;
                setState(() => _pull = 0);
                if (out) widget.onTake(_at);
              }
            : null,
        child: Transform.translate(
          offset: Offset(0, _pull),
          child: LayoutBuilder(
            builder: (context, box) {
              // The tool's own box (aspect ~3.2 : 1), centred in the place.
              final tw = math.min(box.maxWidth * 0.9, box.maxHeight / 3.2);
              final th = tw * 3.2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // The peg hook.
                  Positioned(
                    left: box.maxWidth / 2 - 5,
                    top: (box.maxHeight - th) / 2 - 8,
                    child: Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8A9096), width: 2), borderRadius: BorderRadius.circular(5))),
                  ),
                  Positioned(
                    left: (box.maxWidth - tw) / 2,
                    top: (box.maxHeight - th) / 2,
                    width: tw,
                    height: th,
                    child: RotatedBox(quarterTurns: 1, child: CustomPaint(painter: ToolPainter(t, seen: const {}))),
                  ),
                  if (t.insulated)
                    Positioned(
                      top: (box.maxHeight - th) / 2 + th * 0.7,
                      left: box.maxWidth / 2 - 6,
                      child: const _BlankTag(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The mark seen from a step away: a white tag, its print too small to read.
class _BlankTag extends StatelessWidget {
  const _BlankTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5), border: Border.all(color: const Color(0xFF31363C), width: 0.6)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (var i = 0; i < 2; i++) Container(height: 1.2, color: const Color(0x99555B63))],
      ),
    );
  }
}

/// A packed tool lying in its compartment.
class _Packed extends StatelessWidget {
  const _Packed({required this.tool, required this.quiet});
  final TbTool tool;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, -50 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Center(child: AspectRatio(aspectRatio: 3.2, child: CustomPaint(painter: ToolPainter(tool)))),
    );
  }
}

/// A tool set aside, standing in the crate, tagged বাতিল.
class _AsideTool extends StatelessWidget {
  const _AsideTool({required this.tool, required this.index, required this.quiet});
  final TbTool tool;

  /// Its place in the crate (the tags stagger so each stays readable).
  final int index;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.translate(offset: Offset(-60 * (1 - t), 0), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Transform.rotate(
        angle: 0.08,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Handle up, head down in the crate.
            Positioned.fill(child: RotatedBox(quarterTurns: 3, child: CustomPaint(painter: ToolPainter(tool)))),
            Positioned(
              top: 22.0 + index * 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(2)),
                child: Text(TbLines.rejected, style: bangla(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.onTapUp});
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
                child: Text(TbLines.hold,
                    textAlign: TextAlign.center, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.ivory, height: 1.25)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close look, hands on: the tool held up big, its mark readable; run a
/// finger along it — a crack, a cut, a burn mark, a blunt edge, a bent tip
/// show only where the hand has been. The line tester also gets touched to
/// the known live point (a socket on the store wall): does the neon glow?
/// Then pack it or put it back.
class _Inspect extends StatefulWidget {
  const _Inspect({
    super.key,
    required this.tool,
    required this.deal,
    required this.quiet,
    required this.enabled,
    required this.keys,
    required this.onFound,
    required this.onTouched,
    required this.onMiss,
    required this.onTest,
    required this.onTake,
    required this.onPutBack,
    required this.onAside,
  });
  final TbTool tool;
  final TbDeal deal;
  final bool quiet;

  /// Takes touches (not while the coworker is on).
  final bool enabled;

  /// The gesture hint's anchors: the close-up, the live point, the buttons.
  final ({GlobalKey close, GlobalKey live, GlobalKey back, GlobalKey aside, GlobalKey take}) keys;
  final VoidCallback onFound;

  /// The hand touched the tool (the first time).
  final VoidCallback onTouched;

  /// A tap on nothing round the close look.
  final VoidCallback onMiss;
  final bool? Function() onTest;
  final ValueChanged<Offset> onTake;
  final VoidCallback onPutBack;
  final ValueChanged<Offset> onAside;

  @override
  State<_Inspect> createState() => _InspectState();
}

class _InspectState extends State<_Inspect> {
  final Set<int> _seen = {};
  Offset? _hand;
  var _found = false;
  bool? _lit;

  void _touch(Offset p, Size s) {
    widget.onTouched();
    final b = toolBin(ToolPainter.uAt(s, p.dx));
    final before = _seen.length;
    for (final x in [b - 1, b, b + 1]) {
      if (x >= 0 && x < kToolBins) _seen.add(x);
    }
    final grew = _seen.length != before;
    if (!_found && ToolPainter.flawSeen(widget.tool, _seen)) {
      _found = true;
      widget.onFound();
    }
    if (grew || _hand != p) setState(() => _hand = p);
  }

  void _testIt() {
    if (_lit != null) return;
    final lit = widget.onTest();
    if (lit != null) setState(() => _lit = lit);
  }

  Widget _closeUp(TbTool t) => LayoutBuilder(
        builder: (context, box) {
          final s = Size(box.maxWidth, box.maxHeight);
          return Semantics(
            key: widget.keys.close,
            label: TbLines.handLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _touch(d.localPosition, s),
              onPanUpdate: (d) => _touch(d.localPosition, s),
              onPanEnd: (_) => setState(() => _hand = null),
              onPanCancel: () => setState(() => _hand = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: ToolPainter(t, seen: _seen, veil: _bench, lit: _lit == true))),
                  if (t.insulated)
                    Positioned(
                      left: ToolPainter.xAt(s, 0.74) - 26,
                      top: s.height * 0.5 + s.height * 0.12,
                      child: _Tag(text: t.kind.mark),
                    ),
                  if (_seen.isEmpty) _Puck(at: Offset(ToolPainter.xAt(s, 0.86), s.height * 0.5)),
                  if (_hand != null) _Puck(at: _hand!, live: true),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    final panel = Align(
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
                        child: Text('${TbLines.docket} · ${TbLines.lineBn} · ${t.kind.nameBn}',
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
                  child: Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: _closeUp(t)),
                ),
              ),
              if (t.kind == TbKind.tester) ...[
                const SizedBox(height: 8),
                KeyedSubtree(key: widget.keys.live, child: _LivePoint(lit: _lit, onTap: _testIt)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: DoBigButton(key: widget.keys.back, label: TbLines.putBack, filled: false, onTapUp: (_) => widget.onPutBack())),
                  const SizedBox(width: 8),
                  Expanded(child: DoBigButton(key: widget.keys.aside, label: TbLines.aside, filled: false, onTapUp: (d) => widget.onAside(d.globalPosition))),
                  const SizedBox(width: 8),
                  Expanded(child: DoBigButton(key: widget.keys.take, label: TbLines.take, filled: true, onTapUp: (d) => widget.onTake(d.globalPosition))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: !widget.enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (_) => widget.onMiss(),
          child: ColoredBox(color: const Color(0xC0050A16), child: panel),
        ),
      ),
    );
  }
}

/// The store wall's socket: the known live point the tester's tip is touched to.
class _LivePoint extends StatelessWidget {
  const _LivePoint({required this.lit, required this.onTap});
  final bool? lit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: TbLines.liveLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFE4E7EA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB5BCC4))),
          child: Row(
            children: [
              // The socket plate with its three holes.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF9AA3AC))),
                child: CustomPaint(painter: _SocketPainter(lit: lit)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(TbLines.liveLabel, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: _ink))),
              Icon(
                lit == null ? Icons.touch_app_rounded : (lit! ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded),
                color: lit == true ? const Color(0xFFFF7A1A) : _grey,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocketPainter extends CustomPainter {
  const _SocketPainter({required this.lit});
  final bool? lit;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF2C3238);
    c.drawCircle(Offset(s.width * 0.5, s.height * 0.3), 3.4, p);
    c.drawCircle(Offset(s.width * 0.32, s.height * 0.66), 2.6, p);
    c.drawCircle(Offset(s.width * 0.68, s.height * 0.66), 2.6, p);
    // The switch rocker, ON.
    c.drawRect(Rect.fromLTWH(s.width - 9, 4, 5, 9), Paint()..color = const Color(0xFFD23B2E));
    if (lit == true) {
      c.drawCircle(Offset(s.width * 0.68, s.height * 0.66), 7, Paint()..color = const Color(0x55FF8A1A));
    }
  }

  @override
  bool shouldRepaint(_SocketPainter old) => old.lit != lit;
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

/// The rating as printed on the handle, readable up close (the IEC 60900
/// double triangle beside it).
class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFFE14D), borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFF31363C), width: 1.2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14, height: 12, child: CustomPaint(painter: _DoubleTriangle())),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
        ],
      ),
    );
  }
}

class _DoubleTriangle extends CustomPainter {
  const _DoubleTriangle();

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final dx in [0.0, s.width * 0.42]) {
      final w = s.width * 0.58;
      c.drawPath(
        Path()
          ..moveTo(dx, s.height)
          ..lineTo(dx + w / 2, 0)
          ..lineTo(dx + w, s.height)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_DoubleTriangle old) => false;
}

// ============================================================================
// The tools, drawn
// ============================================================================

/// How many stretches a tool is looked at in.
const kToolBins = 20;
int toolBin(double u) => (u * kToolBins).floor().clamp(0, kToolBins - 1);

/// A hand tool drawn lengthwise, head (jaws / tip) at the left, handle at the
/// right: VDE tools have a thick two-colour insulated handle (red over yellow)
/// with a finger guard; a plain tool has a thin single-colour sleeve and bare
/// metal at the joint. Faults show only once their stretch has been looked at
/// ([seen]: stretches of [kToolBins]; null = all seen); unseen stretches are
/// washed with [veil] when it is set. [lit]: the tester's neon glows.
class ToolPainter extends CustomPainter {
  ToolPainter(this.tool, {this.seen, this.veil, this.lit = false, this.taped = false});
  final TbTool tool;
  final Set<int>? seen;
  final Color? veil;
  final bool lit;

  /// Tape wound over the damaged handle (the coworker's shortcut).
  final bool taped;

  static double _pad(Size s) => s.height * 0.08;
  static double xAt(Size s, double u) => _pad(s) + u * (s.width - 2 * _pad(s));
  static double uAt(Size s, double x) => ((x - _pad(s)) / (s.width - 2 * _pad(s))).clamp(0.0, 1.0);

  /// Where along the tool its fault sits (null: nothing to see by eye).
  static double? flawU(TbTool t) => switch (t.flaw) {
        TbFlaw.none || TbFlaw.deadNeon => null,
        TbFlaw.blunt => 0.13,
        TbFlaw.bentTip => 0.02,
        _ => t.kind == TbKind.screwdriver ? 0.72 : 0.64 + (t.id.codeUnits.last % 3) * 0.07,
      };

  /// The fault is in view: its stretch has been looked at.
  static bool flawSeen(TbTool t, Set<int>? seen) {
    final u = flawU(t);
    if (u == null) return false;
    return seen == null || seen.contains(toolBin(u));
  }

  bool _show(double u) => seen == null || seen!.contains(toolBin(u));

  static const _metal = [Color(0xFFE3E7EA), Color(0xFF8C959D)];
  static const _red = Color(0xFFD62F26);
  static const _yellow = Color(0xFFFFC928);
  static const _plain = Color(0xFF2F5E9E);

  Paint _metalPaint(Rect r) => Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _metal).createShader(r);

  @override
  void paint(Canvas c, Size s) {
    final cy = s.height / 2;
    final h = s.height;
    double x(double u) => xAt(s, u);
    switch (tool.kind) {
      case TbKind.pliers:
      case TbKind.stripper:
        _pliers(c, s, cy, h, x);
      case TbKind.screwdriver:
        _driver(c, s, cy, h, x);
      case TbKind.tester:
        _tester(c, s, cy, h, x);
    }
    _flaw(c, s, cy, h, x);
    final v = veil;
    if (v != null && seen != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.5);
      for (var i = 0; i < kToolBins; i++) {
        if (seen!.contains(i)) continue;
        final a = x(i / kToolBins);
        final b = x((i + 1) / kToolBins);
        c.drawRect(Rect.fromLTRB(a, 0, b + 0.5, s.height), wash);
      }
    }
  }

  /// Handle grip from u0 to u1 along a line from [a] to [b].
  void _grip(Canvas c, Offset a, Offset b, double w) {
    if (tool.insulated) {
      c.drawLine(a, b, Paint()
        ..color = _yellow
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round);
      c.drawLine(a, b, Paint()
        ..color = _red
        ..strokeWidth = w * 0.72
        ..strokeCap = StrokeCap.round);
      c.drawLine(a + Offset(0, -w * 0.16), b + Offset(0, -w * 0.16), Paint()
        ..color = const Color(0x44FFFFFF)
        ..strokeWidth = w * 0.14
        ..strokeCap = StrokeCap.round);
    } else {
      c.drawLine(a, b, Paint()
        ..color = _plain
        ..strokeWidth = w * 0.62
        ..strokeCap = StrokeCap.round);
    }
  }

  void _pliers(Canvas c, Size s, double cy, double h, double Function(double) x) {
    final strip = tool.kind == TbKind.stripper;
    // Jaws.
    final jaw = Path()
      ..moveTo(x(0), cy - h * 0.04)
      ..lineTo(x(0.27), cy - h * 0.17)
      ..lineTo(x(0.3), cy)
      ..lineTo(x(0.27), cy + h * 0.17)
      ..lineTo(x(0), cy + h * 0.04)
      ..close();
    final jr = Rect.fromLTRB(x(0), cy - h * 0.2, x(0.3), cy + h * 0.2);
    c.drawPath(jaw, _metalPaint(jr));
    c.drawLine(Offset(x(0), cy), Offset(x(0.22), cy), Paint()
      ..color = const Color(0xFF4A5056)
      ..strokeWidth = 1.2);
    if (strip) {
      // Stripping notches along the jaw line, and the cutting edge near the joint.
      for (final u in [0.05, 0.09, 0.13]) {
        c.drawCircle(Offset(x(u), cy), h * (0.02 + u * 0.12), Paint()..color = const Color(0xFF4A5056));
      }
      c.drawLine(Offset(x(0.16), cy - h * 0.1), Offset(x(0.24), cy - h * 0.02), Paint()
        ..color = Colors.white
        ..strokeWidth = 1.4);
    } else {
      for (var u = 0.02; u < 0.12; u += 0.025) {
        c.drawLine(Offset(x(u), cy - h * 0.06), Offset(x(u), cy + h * 0.06), Paint()
          ..color = const Color(0x664A5056)
          ..strokeWidth = 1);
      }
    }
    // Joint.
    final joint = Offset(x(0.31), cy);
    c.drawCircle(joint, h * 0.16, _metalPaint(Rect.fromCircle(center: joint, radius: h * 0.16)));
    c.drawCircle(joint, h * 0.05, Paint()..color = const Color(0xFF5A6168));
    // Handles: two grips spreading to the right.
    final spread = h * 0.26;
    final gw = tool.insulated ? h * 0.24 : h * 0.2;
    if (tool.plain) {
      // Bare metal from the joint before the thin sleeve starts.
      for (final dir in [-1.0, 1.0]) {
        c.drawLine(Offset(x(0.33), cy + dir * h * 0.04), Offset(x(0.46), cy + dir * (h * 0.04 + spread * 0.2)), Paint()
          ..color = const Color(0xFF9AA2A9)
          ..strokeWidth = h * 0.1
          ..strokeCap = StrokeCap.round);
      }
    }
    final start = tool.insulated ? 0.36 : 0.46;
    for (final dir in [-1.0, 1.0]) {
      final a = Offset(x(start), cy + dir * (h * 0.06 + spread * (start - 0.33) / 0.67));
      final b = Offset(x(0.99), cy + dir * (h * 0.06 + spread));
      _grip(c, a, b, gw);
    }
    if (tool.insulated) {
      // The finger guard (a collar at the handle's start).
      for (final dir in [-1.0, 1.0]) {
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x(0.38), cy + dir * h * 0.1), width: h * 0.12, height: h * 0.3), Radius.circular(h * 0.05)),
          Paint()..color = _red,
        );
      }
    }
  }

  void _driver(Canvas c, Size s, double cy, double h, double Function(double) x) {
    final bent = tool.flaw == TbFlaw.bentTip && _show(0.02);
    // Shaft.
    final shaft = Rect.fromLTRB(x(0.06), cy - h * 0.05, x(0.5), cy + h * 0.05);
    c.drawRect(shaft, _metalPaint(shaft));
    if (tool.insulated) {
      // Insulated from the handle down to just above the tip.
      final sleeve = Rect.fromLTRB(x(0.1), cy - h * 0.075, x(0.5), cy + h * 0.075);
      c.drawRRect(RRect.fromRectAndRadius(sleeve, Radius.circular(h * 0.04)), Paint()..color = _yellow);
      c.drawRRect(RRect.fromRectAndRadius(sleeve.deflate(h * 0.018), Radius.circular(h * 0.03)), Paint()..color = _red);
    }
    // Tip.
    c.save();
    if (bent) {
      c.translate(x(0.06), cy);
      c.rotate(-0.45);
      c.translate(-x(0.06), -cy);
    }
    final tip = Path()
      ..moveTo(x(0.0), cy - h * 0.03)
      ..lineTo(x(0.06), cy - h * 0.05)
      ..lineTo(x(0.06), cy + h * 0.05)
      ..lineTo(x(0.0), cy + h * 0.03)
      ..close();
    c.drawPath(tip, _metalPaint(Rect.fromLTRB(x(0), cy - h * 0.06, x(0.07), cy + h * 0.06)));
    c.restore();
    // Handle.
    final hr = Rect.fromLTRB(x(0.5), cy - h * 0.22, x(1.0), cy + h * 0.22);
    if (tool.insulated) {
      c.drawRRect(RRect.fromRectAndRadius(hr, Radius.circular(h * 0.14)), Paint()..color = _yellow);
      c.drawRRect(RRect.fromRectAndRadius(hr.deflate(h * 0.03), Radius.circular(h * 0.12)), Paint()..color = _red);
      for (final u in [0.6, 0.7, 0.8, 0.9]) {
        c.drawLine(Offset(x(u), cy - h * 0.15), Offset(x(u), cy + h * 0.15), Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 1.2);
      }
      // The guard ring where the handle meets the sleeve.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x(0.5), cy), width: h * 0.08, height: h * 0.4), Radius.circular(h * 0.03)), Paint()..color = _red);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(hr.deflate(h * 0.03), Radius.circular(h * 0.12)), Paint()..color = const Color(0xCC6B8FB8));
      c.drawLine(Offset(x(0.5), cy), Offset(x(0.94), cy), Paint()
        ..color = const Color(0xFF9AA2A9)
        ..strokeWidth = h * 0.06);
    }
  }

  void _tester(Canvas c, Size s, double cy, double h, double Function(double) x) {
    // Tip and insulated shaft.
    final shaft = Rect.fromLTRB(x(0.0), cy - h * 0.035, x(0.36), cy + h * 0.035);
    c.drawRect(shaft, _metalPaint(shaft));
    final sleeve = Rect.fromLTRB(x(0.06), cy - h * 0.06, x(0.36), cy + h * 0.06);
    c.drawRRect(RRect.fromRectAndRadius(sleeve, Radius.circular(h * 0.03)), Paint()..color = _red);
    // The see-through body with the neon window.
    final body = Rect.fromLTRB(x(0.36), cy - h * 0.16, x(0.94), cy + h * 0.16);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(h * 0.1)), Paint()..color = const Color(0xFFD9E4EC));
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(h * 0.1)), Paint()
      ..color = const Color(0xFF8DA0AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    final neon = Rect.fromLTRB(x(0.5), cy - h * 0.06, x(0.66), cy + h * 0.06);
    if (lit) {
      c.drawOval(neon.inflate(h * 0.12), Paint()..color = const Color(0x55FF8A1A));
    }
    c.drawRRect(RRect.fromRectAndRadius(neon, Radius.circular(h * 0.05)), Paint()..color = lit ? const Color(0xFFFF7A1A) : const Color(0xFF8E8A84));
    // Pocket clip and the metal cap the finger touches.
    c.drawLine(Offset(x(0.7), cy - h * 0.19), Offset(x(0.9), cy - h * 0.19), Paint()
      ..color = const Color(0xFF9AA2A9)
      ..strokeWidth = h * 0.04);
    final cap = Rect.fromLTRB(x(0.93), cy - h * 0.12, x(1.0), cy + h * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(cap, Radius.circular(h * 0.04)), _metalPaint(cap));
  }

  void _flaw(Canvas c, Size s, double cy, double h, double Function(double) x) {
    final u = flawU(tool);
    if (u == null || !_show(u)) return;
    final px = x(u);
    // Handle faults sit on the upper grip (pliers) or the handle (screwdriver).
    final gy = tool.kind == TbKind.screwdriver ? cy : cy - (h * 0.06 + h * 0.26 * (u - 0.33) / 0.67);
    switch (tool.flaw) {
      case TbFlaw.crack:
        final p = Path()
          ..moveTo(px - h * 0.03, gy - h * 0.13)
          ..lineTo(px + h * 0.03, gy - h * 0.04)
          ..lineTo(px - h * 0.02, gy + h * 0.02)
          ..lineTo(px + h * 0.04, gy + h * 0.12);
        c.drawPath(p, Paint()
          ..color = _yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.05);
        c.drawPath(p, Paint()
          ..color = const Color(0xFF1B1B1B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.022);
      case TbFlaw.cut:
        final p = Path()
          ..moveTo(px - h * 0.08, gy - h * 0.06)
          ..lineTo(px, gy + h * 0.02)
          ..lineTo(px + h * 0.08, gy - h * 0.06)
          ..close();
        c.drawPath(p, Paint()..color = const Color(0xFF3A3A3A));
        c.drawLine(Offset(px - h * 0.03, gy - h * 0.02), Offset(px + h * 0.03, gy - h * 0.02), Paint()
          ..color = const Color(0xFFCFD6DC)
          ..strokeWidth = h * 0.025);
      case TbFlaw.burn:
        c.drawOval(Rect.fromCenter(center: Offset(px, gy), width: h * 0.34, height: h * 0.2), Paint()..color = const Color(0xCC2A1A10));
        c.drawOval(Rect.fromCenter(center: Offset(px + h * 0.02, gy), width: h * 0.18, height: h * 0.1), Paint()..color = const Color(0xFF120A06));
      case TbFlaw.blunt:
        // Chipped, rounded-off cutting edge.
        for (final d in [-0.03, 0.0, 0.035]) {
          c.drawCircle(Offset(x(u + d), cy - h * 0.06 + d * h), h * 0.03, Paint()..color = const Color(0xFF3A3F44));
        }
      case TbFlaw.bentTip:
        // The bend itself is drawn with the tip (no ring round it).
        break;
      case TbFlaw.none:
      case TbFlaw.deadNeon:
        break;
    }
    if (taped && tbHandleFlaws.contains(tool.flaw)) {
      // Black tape wound over the damage.
      for (var i = -2; i <= 2; i++) {
        c.drawLine(Offset(px + i * h * 0.06 - h * 0.04, gy - h * 0.16), Offset(px + i * h * 0.06 + h * 0.04, gy + h * 0.16), Paint()
          ..color = const Color(0xEE202226)
          ..strokeWidth = h * 0.07);
      }
    }
  }

  @override
  bool shouldRepaint(ToolPainter old) =>
      old.tool != tool || old.lit != lit || old.taped != taped || old.veil != veil || old.seen?.length != seen?.length;
}

// ============================================================================
// The deadly move
// ============================================================================

/// The deadly move, in colour over the frozen store, staged as its own
/// picture: up at the LT line, the gloved hand holds the tool — a plain one,
/// or the cracked handle under tape — its jaws on a conductor; a spark at the
/// jaws, and the current creeps down the tool to the hand. (An illustration of
/// the lesson's "Non-insulated Pliers LT Line-এ = বিপদ" and the myth's
/// "Gloves বা Tool যেকোনো একটি Fail হলেই Shock".)
class _ToolFlash extends StatelessWidget {
  const _ToolFlash({required this.tool, required this.taped, required this.quiet});
  final TbTool tool;
  final bool taped;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 340.0);
        final h = math.min(w * 0.95, box.maxHeight * 0.66);
        return Align(
          alignment: const Alignment(0, -0.25),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1700),
            builder: (_, t, _) {
              final pop = (t * 6).clamp(0.0, 1.0);
              return Opacity(
                opacity: pop,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * pop,
                  child: Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SlmColors.danger, width: 2.5),
                      boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomPaint(size: Size(w, h), painter: _FlashPainter(tool: tool, taped: taped, t: t)),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FlashPainter extends CustomPainter {
  _FlashPainter({required this.tool, required this.taped, required this.t});
  final TbTool tool;
  final bool taped;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    // Sky.
    final sky = Offset.zero & s;
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E9CC6), Color(0xFFC9DCEA)]).createShader(sky));
    // The pole top and the LT conductors across.
    c.drawRect(Rect.fromLTWH(w * 0.82, 0, w * 0.07, h), Paint()..color = const Color(0xFF9AA0A5));
    c.drawRect(Rect.fromLTWH(w * 0.55, h * 0.14, w * 0.45, h * 0.04), Paint()..color = const Color(0xFF6F757A));
    final wire = Paint()
      ..color = const Color(0xFF2A2E33)
      ..strokeWidth = 2.6;
    final wy = h * 0.28;
    for (final dy in [0.0, h * 0.1, h * 0.2]) {
      c.drawLine(Offset(0, wy + dy), Offset(w, wy + dy - h * 0.02), wire);
    }
    // The tool from the hand (bottom left) up to the first conductor.
    final hand = Offset(w * 0.22, h * 0.86);
    final head = Offset(w * 0.56, wy - h * 0.005);
    final len = (head - hand).distance;
    final ang = math.atan2(head.dy - hand.dy, head.dx - hand.dx);
    // The arm and sleeve.
    c.drawLine(Offset(-w * 0.05, h * 1.05), hand, Paint()
      ..color = const Color(0xFF6B5B45)
      ..strokeWidth = h * 0.12
      ..strokeCap = StrokeCap.round);
    c.save();
    c.translate(head.dx, head.dy);
    c.rotate(ang + math.pi);
    // The painter draws head-left; rotate so the head sits at `head`.
    final ts = Size(len * 1.05, len * 1.05 / 3.2);
    c.translate(-ts.width * 0.02, -ts.height / 2);
    ToolPainter(tool, taped: taped).paint(c, ts);
    c.restore();
    // The gloved hand.
    c.drawCircle(hand, h * 0.075, Paint()..color = const Color(0xFFE8B23A));
    // The spark at the jaws.
    final sp = (t * 4).clamp(0.0, 1.0);
    c.drawCircle(head, h * (0.06 + 0.1 * sp), Paint()..color = Color.fromRGBO(255, 240, 160, 0.9 * (1 - 0.5 * sp)));
    final rng = math.Random(7);
    final ray = Paint()
      ..color = const Color(0xFFFFF59D)
      ..strokeWidth = 2;
    for (var i = 0; i < 9; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      c.drawLine(head, head + Offset(math.cos(a), math.sin(a)) * h * (0.08 + 0.12 * sp * rng.nextDouble()), ray);
    }
    // The current creeping down the tool to the hand.
    final reach = ((t - 0.2) / 0.6).clamp(0.0, 1.0);
    if (reach > 0) {
      final path = Path()..moveTo(head.dx, head.dy);
      const n = 10;
      for (var i = 1; i <= (n * reach).ceil(); i++) {
        final p = Offset.lerp(head, hand, i / n)!;
        final nrm = Offset(-math.sin(ang), math.cos(ang)) * (i.isEven ? 6.0 : -6.0);
        path.lineTo(p.dx + nrm.dx, p.dy + nrm.dy);
      }
      c.drawPath(path, Paint()
        ..color = const Color(0xFFFF2D2D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2);
      if (reach >= 1) {
        c.drawCircle(hand, h * 0.12, Paint()..color = const Color(0x66FF2D2D));
      }
    }
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.t != t;
}
