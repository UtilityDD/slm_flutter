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
import 'm4_jumper_tight_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_jumper_tight_world.dart' show M4JumperTightKind;

// Lesson 4.2 "জাম্পার কানেকশন ও টাইট করা", কাজ 2 "ঢিলে জাম্পার ধরো"
// (pack do_4_2_b, engineType m4_jumper_tight). Three angle poles a play on the
// village road, each with one bad jumper connection: at night a red-hot glow
// or sparking, by day a melted clamp. The trainee spots the bad PG clamp, then
// puts it right — safely — and looks at it again once the line is back.
//
// The lesson's rules, and only those:
//   • point 2 (loose jumper): a loose connection heats up (hotspot), glows red
//     at night, sparks; the connector can melt and the wire fall;
//   • point 1 (the method) + pro tips 1 and 4: clean the surfaces with a steel
//     brush and put anti-oxidant paste on, tighten the nuts and bolts evenly to
//     the right torque, two wrenches (one holds the bolt head, one turns the
//     nut);
//   • myths 1 and 2 and the I²R fact for the reason cards.
// From the module's safety rules (the brief, lesson 1.6 — NOT lesson 4.2's
// text, whose safety tip calls the job live-line maintenance; flagged in
// REGISTER.md): the work is done only after a shutdown with PTW, the line
// proven dead with a tester and earthed; the earth comes off before the PTW
// goes back. Inferred and flagged: a melted clamp is replaced, not tightened;
// going past the right torque is a slip (the lesson gives no torque value —
// the dial's band is a game abstraction).
//
// Hands on: tap the bad clamp (spot) · শাটডাউন (PTW) · টেস্টার · আর্থ ·
// ব্রাশ (steel brush + paste) · ক্ল্যাম্প (a new PG clamp) · রেঞ্চ (two
// wrenches; hold "টাইট দিন" until the needle is in the band) · শাটডাউন again
// (the PTW back, the line live) · tap the clamp again (recheck).
//
// Deadly: any tool on a jumper while the line is live (also by listening to
// the coworker, "চালু অবস্থায় প্লাস দিয়ে একটু টাইট দাও!"). Slips: the wrong
// clamp, work or earth before proving dead, work before the earth, tightening
// before cleaning, tightening a melted clamp, past the right torque, the line
// back with the earth on, the line back before the fix. Three slips strike the
// level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m4_jumper_tight_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next pole by itself; the careless coworker once a play, after the spot,
// before the shutdown; a fast শাটডাউন waits for him (holdForCoworker). Voice:
// the guide by device TTS; the coworker's push has no clip yet (the kit holds
// his caption silently) and his exit line is his existing recorded clip.
//
// No giveaways: the tool row is dealt in a fresh order for every pole (never
// the work order); a wrong clamp costs a slip and its card stays neutral.
// Gesture hints: a sweep over the clamps (spot) and over the tools, a tap on
// the spotted clamp with a tool in hand / for the recheck, a hold on টাইট দিন.

// ============================================================================
// Content
// ============================================================================

/// What the reason question asks about.
enum M4JumperTightWhy { sign, isolate, clean, wrench, replace, recheck }

/// The hands-on tools that go on the clamp.
enum M4JumperTightTool { none, brush, clamp, wrench }

/// The buttons of the tool row (declared in the work order; the row is dealt
/// shuffled, never in this order).
enum M4JumperTightControl { shutdown, tester, earth, brush, clamp, wrench }

/// A tool row in a fresh order that is never the work order.
List<M4JumperTightControl> m4JumperTightToolRow(math.Random rng) {
  const work = M4JumperTightControl.values;
  final row = [...work]..shuffle(rng);
  var same = true;
  for (var i = 0; i < row.length; i++) {
    if (row[i] != work[i]) same = false;
  }
  if (same) {
    final first = row.removeAt(0);
    row.add(first);
  }
  return row;
}

@immutable
class M4JumperTightSite {
  const M4JumperTightSite({required this.id, required this.kind, required this.phase, required this.end, required this.why});
  final String id;
  final M4JumperTightKind kind;

  /// The bad clamp: phase 0 (top) → 2, end 0 (left) / 1 (right).
  final int phase;
  final int end;
  final M4JumperTightWhy why;
}

abstract final class M4JumperTightLines {
  static const title = 'ঢিলে জাম্পার ধরো';
  static const intro = 'টহলে বেরোন — ঢিলে জাম্পার খুঁজে নিরাপদে ঠিক করুন!';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askSpot = 'কোন জাম্পারের জোড়া খারাপ? খুঁজুন।';
  static const askSafe = 'ধরেছেন! এবার নিরাপদে ঠিক করুন।';
  static const askFix = 'জোড়াটা ঠিক করুন।';
  static const askTorque = 'সঠিক টর্কে টাইট দিন।';
  static const askBack = 'কাজ শেষ — লাইন ফেরান।';
  static const askCheck = 'জোড়াটা আবার দেখুন।';
  static const tasks = [askSpot, askSafe, askFix, askTorque, askBack, askCheck];
  static const torqueMore = 'আরেকটু — সঠিক টর্ক পর্যন্ত।';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the permit, the tester).
  static const sceneLabel = 'জাম্পার পোল';
  static const shutdown = 'শাটডাউন';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const brush = 'ব্রাশ';
  static const clamp = 'ক্ল্যাম্প';
  static const wrench = 'রেঞ্চ';
  static const tighten = 'টাইট দিন';
  static const ptw = 'PTW';
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const stampDone = 'জোড়া ঠিক';

  // The reasons (lesson 4.2): the right ones fit this pole and what was done;
  // the wrong ones are the lesson's myths and field excuses — never a true
  // rule marked wrong. Every card 40–48 letters.
  static const whySignQ = 'কেন ওই জোড়াটাকেই খারাপ ধরলেন?';
  static const whyIsolateQ = 'কেন হাত দেওয়ার আগে শাটডাউন আর আর্থ?';
  static const whyCleanQ = 'কেন টাইটের আগে ব্রাশ আর পেস্ট?';
  static const whyWrenchQ = 'কেন দুটি রেঞ্চে, সঠিক টর্কে টাইট?';
  static const whyReplaceQ = 'কেন গলা ক্ল্যাম্পটা বদলালেন?';
  static const whyRecheckQ = 'কেন লাইন চালুর পর আবার দেখলেন?';
  static const signWhy = ['ঢিলে জোড়ায় রেজিস্ট্যান্স বেশি, তাই গরম হয়', 'রাতে লাল আভা আর স্পার্কিং — ঢিলে জাম্পারের লক্ষণ'];
  static const isolateWhy = ['চালু জাম্পারে হাত দিলে মৃত্যু, তাই আগে শাটডাউন', 'শাটডাউন, টেস্টারে মৃত, আর্থ — তবেই হাত দেওয়া'];
  static const cleanWhy = ['ময়লা আর অক্সাইড থাকলে ভালো ক্ল্যাম্পও গরম হয়', 'পরিষ্কার জোড়াই টেকে, তাই স্টিল ব্রাশ আর পেস্ট'];
  static const wrenchWhy = ['এক রেঞ্চে বোল্ট ধরে অন্যটায় নাট, তবে চেপে বসে', 'নাট-বল্টু সমানভাবে, সঠিক টর্কে — কম-বেশি নয়'];
  static const replaceWhy = ['গলা ক্ল্যাম্পে তার খসে পড়তে পারে, তাই নতুনটা', 'গলে যাওয়া কানেক্টর রাখলে তার ছিঁড়ে পড়তে পারে'];
  static const recheckWhy = ['লাল আভা বা স্পার্কিং আর নেই কি না দেখে নিলাম', 'জোড়া সত্যিই ঠিক হলো কি না, চালুর পর দেখা চাই'];
  static const myths = [
    'ঝুলন্ত জাম্পার একটু ঢিলে থাকলেও কিছু হয় না',
    'যেকোনো সরু তারেই জাম্পার বানিয়ে দেওয়া যায়',
    'যত জোরে পারি টাইট দিলে জোড়া তত ভালো হয়',
    'প্লাস দিয়ে চালু লাইনেই একটু টাইট দেওয়া যায়',
    'জাম্পারে টান নেই, তাই ওখানে কারেন্টও কম থাকে',
    'লাল আভাটা তো রাতের আলো, ওতে ভয়ের কিছু নেই',
    'শাটডাউন নিলে দেরি হয়, তাই চালুতেই সারলাম',
  ];
  static const allRight = [...signWhy, ...isolateWhy, ...cleanWhy, ...wrenchWhy, ...replaceWhy, ...recheckWhy];

  static List<String> whyRight(M4JumperTightSite s) => switch (s.why) {
        M4JumperTightWhy.sign => signWhy,
        M4JumperTightWhy.isolate => isolateWhy,
        M4JumperTightWhy.clean => cleanWhy,
        M4JumperTightWhy.wrench => wrenchWhy,
        M4JumperTightWhy.replace => replaceWhy,
        M4JumperTightWhy.recheck => recheckWhy,
      };
  static String whyQuestion(M4JumperTightSite s) => switch (s.why) {
        M4JumperTightWhy.sign => whySignQ,
        M4JumperTightWhy.isolate => whyIsolateQ,
        M4JumperTightWhy.clean => whyCleanQ,
        M4JumperTightWhy.wrench => whyWrenchQ,
        M4JumperTightWhy.replace => whyReplaceQ,
        M4JumperTightWhy.recheck => whyRecheckQ,
      };

  /// The careless coworker: tighten it live, with pliers.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'চালু অবস্থায় প্লাস দিয়ে একটু টাইট দাও! শাটডাউন নিতে অনেক দেরি।',
    exitLine: coworkerExit,
    right: ['না, আগে শাটডাউন, টেস্ট আর আর্থ — তবে টাইট', 'না, চালু জাম্পারে প্লাস-রেঞ্চ কিছুই নয়', 'না, শাটডাউন নিয়ে দুটি রেঞ্চে টাইট দেব'],
    wrong: [
      'ঠিক, প্লাস দিয়ে চালুতেই একটু টাইট দিই',
      'আচ্ছা, গ্লাভস তো পরা, চালুতেই সারি',
      'শাটডাউনের ঝামেলা না করে টাইট দিই',
      'ঠিক আছে, এক মিনিটের কাজ, চালুতেই',
      'হ্যাঁ, সাবধানে চালু জাম্পারেই টাইট দিই',
    ],
    asks: ['ও বলছে চালু অবস্থায় টাইট দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'চালু জাম্পারে প্লাস দেবেন?'],
  );

  static const callHeld = 'ঠিক! চালু জাম্পারে কখনো হাত নয়।';
  static const allSet = 'তিনটে জোড়াই ঠিক — নিরাপদে, সঠিক টর্কে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে শাটডাউন, তারপর পরিষ্কার করে টাইট।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtSpot = 'খারাপ জাম্পার জোড়া খুঁজে পেয়েছেন';
  static const caughtSafe = 'শাটডাউন, টেস্ট, আর্থ — তবে হাত';
  static const caughtClean = 'ব্রাশ আর পেস্টে পরিষ্কার জোড়া';
  static const caughtTorque = 'দুটি রেঞ্চে সঠিক টর্কে টাইট';
  static const caughtReplace = 'গলা ক্ল্যাম্প বদলেছেন';
  static const caughtCheck = 'লাইন চালুর পর আবার দেখেছেন';
  static const caughtCall = 'চালু জাম্পারে “না” বলেছেন';
}

abstract final class M4JumperTightMistakes {
  static const _dir = 'assets/game/art/m4_jumper_tight';
  static const _live = '$_dir/work_live.svg';
  static const _spot = '$_dir/mis_spot.svg';
  static const _isolate = '$_dir/isolate.svg';
  static const _clean = '$_dir/clean.svg';
  static const _torque = '$_dir/torque.svg';
  static const _melted = '$_dir/melted.svg';
  static const _earthOn = '$_dir/earth_on.svg';

  static const workLive = DoMistake(
    key: '4.2/m4_jumper_tight/work-live',
    textBn: 'চালু জাম্পারে প্লাস-রেঞ্চ নয়! আগে শাটডাউন ও PTW, টেস্টারে মৃত প্রমাণ, আর্থ — তবেই টাইট।',
    art: _live,
    deadly: true,
    lessonPoint: 2,
  );
  static const misSpot = DoMistake(
    key: '4.2/m4_jumper_tight/wrong-clamp',
    textBn: 'আন্দাজে নয় — লক্ষণ দেখে ধরুন। খারাপ জাম্পারের লক্ষণ: রাতে লাল আভা, স্পার্কিং, গলা ক্ল্যাম্প।',
    art: _spot,
    lessonPoint: 2,
  );
  // Proving dead and the earth come from the module's rules (lesson 1.6), not
  // lesson 4.2's text: no lesson point here.
  static const noProve = DoMistake(
    key: '4.2/m4_jumper_tight/not-proven-dead',
    textBn: 'শাটডাউনের পর আগে টেস্টারে মৃত প্রমাণ করুন — তবেই আর্থ, তবেই হাত।',
    art: _isolate,
  );
  static const noEarth = DoMistake(
    key: '4.2/m4_jumper_tight/no-earth',
    textBn: 'মৃত প্রমাণের পর আর্থ লাগান — তবেই জাম্পারে হাত দিন।',
    art: _isolate,
  );
  static const noClean = DoMistake(
    key: '4.2/m4_jumper_tight/not-cleaned',
    textBn: 'আগে স্টিল ব্রাশে ময়লা-অক্সাইড তুলে অ্যান্টি-অক্সিডেন্ট পেস্ট — নইলে সবচেয়ে ভালো কানেক্টরও ব্যর্থ হয়।',
    art: _clean,
    lessonPoint: 1,
  );
  static const meltedTighten = DoMistake(
    key: '4.2/m4_jumper_tight/melted-tightened',
    textBn: 'ক্ল্যাম্প গলে গেছে — টাইট দিয়ে লাভ নেই, তার খসে পড়তে পারে। নতুন ক্ল্যাম্প লাগান।',
    art: _melted,
    lessonPoint: 2,
  );
  static const overTight = DoMistake(
    key: '4.2/m4_jumper_tight/over-tight',
    textBn: 'সঠিক টর্কে টাইট দিন, তার বেশি নয় — বেশি টাইটে বোল্ট আর ক্ল্যাম্প নষ্ট হয়।',
    art: _torque,
    lessonPoint: 1,
  );
  static const earthOn = DoMistake(
    key: '4.2/m4_jumper_tight/earth-left-on',
    textBn: 'আর্থ লাগানো রেখে লাইন চালু নয়! আগে সব আর্থ খুলুন, তারপর PTW ফেরত।',
    art: _earthOn,
  );
  static const unfinished = DoMistake(
    key: '4.2/m4_jumper_tight/back-unfixed',
    textBn: 'কাজ শেষ হয়নি — ঢিলে বা গলা জোড়া রেখে লাইন চালু করলে আবার গরম হয়ে ফল্ট হবে।',
    art: _spot,
    lessonPoint: 2,
  );

  static const all = [workLive, misSpot, noProve, noEarth, noClean, meltedTighten, overTight, earthOn, unfinished];
}

/// The band on the torque dial where the nut is right (0 → 1 over a full hold).
const kM4JumperTightLo = 0.62;
const kM4JumperTightHi = 0.84;

@immutable
class M4JumperTightDeal {
  const M4JumperTightDeal({required this.sites, required this.callAt, this.tools = const []});
  final List<M4JumperTightSite> sites;

  /// The pole the careless coworker comes to.
  final int callAt;

  /// The tool row of each pole (dealt shuffled).
  final List<List<M4JumperTightControl>> tools;

  /// The tool row of pole [i] (a hand-made deal without rows: one fixed
  /// non-work order).
  List<M4JumperTightControl> toolsAt(int i) => i < tools.length ? tools[i] : m4JumperTightToolRow(math.Random(i));
}

/// Three poles: a glowing, a sparking and a melted clamp (any order), each on
/// a dealt phase and side; the melted one asks why it was replaced, the two
/// loose ones ask two different reasons.
M4JumperTightDeal m4JumperTightDeal(math.Random rng) {
  final kinds = [...M4JumperTightKind.values]..shuffle(rng);
  final whys = [M4JumperTightWhy.sign, M4JumperTightWhy.isolate, M4JumperTightWhy.clean, M4JumperTightWhy.wrench, M4JumperTightWhy.recheck]..shuffle(rng);
  var w = 0;
  final sites = <M4JumperTightSite>[
    for (final (i, k) in kinds.indexed)
      M4JumperTightSite(
        id: 'j$i',
        kind: k,
        phase: rng.nextInt(3),
        end: rng.nextInt(2),
        why: k == M4JumperTightKind.melted ? M4JumperTightWhy.replace : whys[w++],
      ),
  ];
  final callAt = rng.nextInt(sites.length);
  return M4JumperTightDeal(sites: sites, callAt: callAt, tools: [for (var i = 0; i < sites.length; i++) m4JumperTightToolRow(rng)]);
}

/// The play state (pure logic).
class M4JumperTightRun {
  M4JumperTightRun(this.deal);
  final M4JumperTightDeal deal;
  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this pole ---
  var spotted = false;
  var shutdown = false;
  var proved = false;
  var earthed = false;
  var cleaned = false;
  var replaced = false;
  var tightened = false;
  var wrenchOn = false;
  var back = false;
  var checked = false;
  M4JumperTightTool tool = M4JumperTightTool.none;

  bool get done => index >= deal.sites.length;
  bool get ended => done || deadly != null;
  M4JumperTightSite get site => deal.sites[index.clamp(0, deal.sites.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  bool get live => !shutdown;
  bool get melted => site.kind == M4JumperTightKind.melted;

  /// The connection is right again (tight; and new, where it had melted).
  bool get fixed => tightened && (!melted || replaced);

  /// He is up the pole (the line dead and earthed).
  bool get up => shutdown && earthed;

  /// Done this pole without a slip (+5 on the table).
  bool get thorough => siteSlips == 0;

  bool get _open => !ended && !checked;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  /// Picks up [t] (or puts it down, if held).
  void hold(M4JumperTightTool t) {
    if (!_open || !spotted || wrenchOn) return;
    tool = tool == t ? M4JumperTightTool.none : t;
  }

  /// Taps the PG clamp of [phase] at [end] (with the tool in hand, if any).
  DoMistake? tapClamp(int phase, int end) {
    if (!_open || wrenchOn) return null;
    final bad = phase == site.phase && end == site.end;
    if (!spotted) {
      if (!bad) return _slip(M4JumperTightMistakes.misSpot);
      spotted = true;
      _tag(M4JumperTightLines.caughtSpot);
      return null;
    }
    if (tool == M4JumperTightTool.none) {
      if (bad && back && fixed) {
        checked = true;
        _tag(M4JumperTightLines.caughtCheck);
      }
      return null;
    }
    if (live) return deadly = M4JumperTightMistakes.workLive;
    if (!bad) return null;
    if (!proved) return _slip(M4JumperTightMistakes.noProve);
    if (!earthed) return _slip(M4JumperTightMistakes.noEarth);
    switch (tool) {
      case M4JumperTightTool.none:
        return null;
      case M4JumperTightTool.brush:
        cleaned = true;
        tool = M4JumperTightTool.none;
        _tag(M4JumperTightLines.caughtClean);
        return null;
      case M4JumperTightTool.clamp:
        if (!cleaned) return _slip(M4JumperTightMistakes.noClean);
        replaced = true;
        tightened = false;
        tool = M4JumperTightTool.none;
        if (melted) _tag(M4JumperTightLines.caughtReplace);
        return null;
      case M4JumperTightTool.wrench:
        if (!cleaned) return _slip(M4JumperTightMistakes.noClean);
        if (melted && !replaced) return _slip(M4JumperTightMistakes.meltedTighten);
        if (tightened) {
          tool = M4JumperTightTool.none;
          return null;
        }
        wrenchOn = true;
        return null;
    }
  }

  /// He lets go of the wrenches with the needle at [v] (0 → 1). Below the band
  /// the nut is still loose (no slip, keep turning); past it is a slip.
  DoMistake? torque(double v) {
    if (!_open || !wrenchOn) return null;
    if (v > kM4JumperTightHi) return _slip(M4JumperTightMistakes.overTight);
    if (v < kM4JumperTightLo) return null;
    tightened = true;
    wrenchOn = false;
    tool = M4JumperTightTool.none;
    _tag(M4JumperTightLines.caughtTorque);
    return null;
  }

  /// শাটডাউন: takes the PTW (the line goes dead) or gives it back (the line
  /// comes back on) — only with the earth off and the job done.
  DoMistake? toggleShutdown() {
    if (!_open || !spotted || wrenchOn) return null;
    if (!shutdown) {
      shutdown = true;
      back = false;
      return null;
    }
    if (earthed) return _slip(M4JumperTightMistakes.earthOn);
    if (!fixed) return _slip(M4JumperTightMistakes.unfinished);
    shutdown = false;
    proved = false;
    back = true;
    tool = M4JumperTightTool.none;
    return null;
  }

  /// The tester on the line: true = live.
  bool test() {
    if (_open && spotted && shutdown) proved = true;
    return live;
  }

  /// The portable earth set on (only on a line proven dead) or off.
  DoMistake? toggleEarth() {
    if (!_open || !spotted || wrenchOn) return null;
    if (earthed) {
      earthed = false;
      tool = M4JumperTightTool.none;
      return null;
    }
    if (!shutdown || !proved) return _slip(M4JumperTightMistakes.noProve);
    earthed = true;
    _tag(M4JumperTightLines.caughtSafe);
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    siteSlips = 0;
    spotted = false;
    shutdown = false;
    proved = false;
    earthed = false;
    cleaned = false;
    replaced = false;
    tightened = false;
    wrenchOn = false;
    back = false;
    checked = false;
    tool = M4JumperTightTool.none;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   a pole: spot, শাটডাউন, টেস্টার ~2500, আর্থ, ব্রাশ + tap, রেঞ্চ + tap,
///     the hold ~2000, আর্থ off, শাটডাউন (back), recheck, the stamp,
///     reason ~8200                                              ≈ 30200 × 3
///   the melted pole: ক্ল্যাম্প + tap                              ≈ 3000
/// + the coworker once ≈ 9600                                     ≈ 103200
/// 85 % ≈ 88000 → 90 s.
const kM4JumperTightQuickMs = 90000;

@immutable
class M4JumperTightPack {
  const M4JumperTightPack({required this.id, required this.titleBn, this.quickMs = kM4JumperTightQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4JumperTightPack> m4JumperTightPacks = {
  'do_4_2_b': M4JumperTightPack(id: 'do_4_2_b', titleBn: M4JumperTightLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4JumperTightPage extends StatefulWidget {
  const M4JumperTightPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4JumperTightPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4JumperTightPage> createState() => _M4JumperTightPageState();
}

class _M4JumperTightPageState extends State<M4JumperTightPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _JumperRunPage(
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

class _JumperRunPage extends ConsumerStatefulWidget {
  const _JumperRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4JumperTightPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_JumperRunPage> createState() => _JumperRunPageState();
}

class _JumperRunPageState extends ConsumerState<_JumperRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4JumperTightRun _run = M4JumperTightRun(m4JumperTightDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The torque needle while he holds the wrenches (0 → 1 over a full hold).
  late final AnimationController _torque = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _letGo();
    });
  var _turning = false;

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
  var _coworkerArmed = false;

  /// The tester's lamp, a moment after it touches the line.
  bool? _tester;
  Timer? _testerTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  // Gesture hints (how, never what).
  final _hints = IdleHintController();
  final _toolKeys = {for (final c in M4JumperTightControl.values) c: GlobalKey()};
  final _tightKey = GlobalKey();
  M4JumperTightGeo? _geo;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
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
    _startSite();
  }

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.checked && !_freeze;

  String get _task {
    if (!_run.spotted) return M4JumperTightLines.askSpot;
    if (_run.wrenchOn) return M4JumperTightLines.askTorque;
    if (_run.back) return M4JumperTightLines.askCheck;
    if (_run.fixed) return M4JumperTightLines.askBack;
    if (!_run.up) return M4JumperTightLines.askSafe;
    return M4JumperTightLines.askFix;
  }

  void _startSite() {
    _testerTimer?.cancel();
    _torque.value = 0;
    setState(() {
      _tester = null;
      _wake++;
    });
    unawaited(_sayChain([M4JumperTightLines.askSpot]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _hold(M4JumperTightTool t) {
    if (!_canPlay || _run.wrenchOn) return;
    _tick('sounds/quiz_select.wav');
    setState(() {
      _run.hold(t);
      _wake++;
    });
  }

  void _useTester() {
    if (!_canPlay || _run.wrenchOn) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final live = _run.test();
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
  }

  void _shutdown(Offset origin) {
    if (!_canPlay) return;
    // The shutdown ends his moment: he cuts in first, however fast the play.
    if (holdForCoworker()) return;
    final wasLive = _run.live;
    final m = _run.toggleShutdown();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _tick('sounds/intro/impact_metal.ogg', 0.6);
    if (wasLive != _run.live) unawaited(_sayChain([_task]));
  }

  void _earth(Offset origin) {
    if (!_canPlay) return;
    final m = _run.toggleEarth();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _tick('sounds/learn/tag_slap.wav', 0.5);
    if (_run.up) unawaited(_sayChain([_task]));
  }

  void _tapScene(Offset p, M4JumperTightGeo geo, Offset global) {
    if (!_canPlay) return;
    for (var i = 0; i < 3; i++) {
      for (var e = 0; e < 2; e++) {
        if (!geo.clampHit(i, e).contains(p)) continue;
        final before = (_run.spotted, _run.cleaned, _run.replaced, _run.wrenchOn);
        final m = _run.tapClamp(i, e);
        setState(() => _wake++);
        if (m != null) {
          unawaited(_mistake(m, global));
          return;
        }
        if (_run.checked) {
          unawaited(_siteDone());
          return;
        }
        final after = (_run.spotted, _run.cleaned, _run.replaced, _run.wrenchOn);
        if (before != after) {
          HapticFeedback.lightImpact();
          _cue(after.$1 && !before.$1 ? 'sounds/quiz_right.wav' : 'sounds/learn/tag_slap.wav', volume: 0.5);
          if (after.$1 && !before.$1 && !_coworkerArmed && _run.index == _run.deal.callAt) {
            _coworkerArmed = true;
            scheduleCoworker();
          }
          unawaited(_sayChain([_task]));
        } else {
          _tick();
          _hints.missTap();
        }
        return;
      }
    }
    _hints.missTap();
  }

  // --- the torque hold -------------------------------------------------------
  void _press() {
    if (!_canPlay || !_run.wrenchOn || _turning) return;
    _turning = true;
    _tick('sounds/intro/click.ogg', 0.4);
    unawaited(_torque.forward());
  }

  void _letGo() {
    if (!_turning) return;
    _turning = false;
    _torque.stop();
    if (!_canPlay || !_run.wrenchOn) return;
    final size = MediaQuery.sizeOf(context);
    final origin = Offset(size.width / 2, size.height - 80);
    final m = _run.torque(_torque.value);
    if (m != null) {
      _torque.value = 0;
      setState(() => _wake++);
      unawaited(_mistake(m, origin));
      return;
    }
    if (_run.tightened) {
      HapticFeedback.mediumImpact();
      _cue('sounds/learn/tag_slap.wav', volume: 0.6);
      _torque.value = 0;
      setState(() => _wake++);
      unawaited(_sayChain([_task]));
    } else {
      unawaited(_sayChain([M4JumperTightLines.torqueMore]));
    }
  }

  Future<void> _siteDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.7);
    _cue('sounds/quiz_right.wav', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final s = _run.site;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M4JumperTightLines.whyRight(s), M4JumperTightLines.myths, widget.rng),
      question: M4JumperTightLines.whyQuestion(s),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startSite();
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
    final idx = _run.index;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 500 : 1100), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4JumperTightLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || !_run.spotted || _run.shutdown || _run.back || _run.checked) return null;
    if (_intro || _card != null || tableBusy || _tester != null || _run.tool != M4JumperTightTool.none) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: pliers on the live jumper.
      _run.failDeadly(M4JumperTightMistakes.workLive);
      await _deadly(M4JumperTightMistakes.workLive);
      return;
    }
    _run.caught.add(M4JumperTightLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M4JumperTightLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4JumperTightLines.tapWhy[_nudgeN++ % M4JumperTightLines.tapWhy.length]
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
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('jumper/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A tool on a live jumper: the pole freezes grey and the flash comes off
  /// the clamp in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _testerTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _tester = null;
    });
    await frozen.future;
    if (!mounted) return;
    _cue('sounds/accident.wav', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('jumper/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4JumperTightLines.deadlyWord : M4JumperTightLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same pole goes on from where it was.
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
    await _say(!_run.passed ? M4JumperTightLines.fail : (_quickBonus ? M4JumperTightLines.quick : M4JumperTightLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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

  // --- gesture hints -----------------------------------------------------------
  /// The waiting state now (a new one resets the hint count).
  Object get _hintKey => (
        _run.index,
        _run.spotted,
        _run.tool,
        _run.wrenchOn,
        _run.shutdown,
        _run.proved,
        _run.earthed,
        _run.cleaned,
        _run.replaced,
        _run.tightened,
        _run.back,
      );

  /// How to play now — never which clamp or which tool is right.
  HintSpec? _hint() {
    final geo = _geo;
    if (geo == null) return null;
    if (!_run.spotted) {
      // One of these clamps is the bad one: glide over all six.
      return HintSpec.sweep([
        for (var i = 0; i < 3; i++)
          for (var e = 0; e < 2; e++) geo.clampHit(i, e),
      ], space: HintSpace.scene);
    }
    if (_run.wrenchOn) return HintSpec.holdOn(_tightKey);
    final s = _run.site;
    // A tool in hand goes on the (already found) clamp — but only once he is
    // up (shut down, proved, earthed) and only when that tap books nothing:
    // on a live or unearthed line it is death or a slip, and so is a clamp or
    // the wrenches before the brush (or the wrenches on a melted one before
    // the new clamp). Otherwise the hint stays a sweep over the tool row.
    // The recheck (the line back on, empty-handed) is a tap on the clamp.
    final held = _run.tool != M4JumperTightTool.none;
    final safeTap = _run.up &&
        switch (_run.tool) {
          M4JumperTightTool.none => false,
          M4JumperTightTool.brush => true,
          M4JumperTightTool.clamp => _run.cleaned,
          M4JumperTightTool.wrench => _run.cleaned && (!_run.melted || _run.replaced),
        };
    if (safeTap || (!held && _run.back && _run.fixed)) {
      return HintSpec.tap(geo.clamp(s.phase, s.end), space: HintSpace.scene);
    }
    return HintSpec.sweepOver([for (final c in _run.deal.toolsAt(_run.index)) _toolKeys[c]!]);
  }

  Widget _toolButton(M4JumperTightControl c) => switch (c) {
        M4JumperTightControl.shutdown => _ToolButton(
            key: _toolKeys[c],
            icon: Icons.power_settings_new_rounded,
            label: M4JumperTightLines.shutdown,
            on: _run.shutdown,
            onTapUp: (d) => _shutdown(d.globalPosition)),
        M4JumperTightControl.tester =>
          _ToolButton(key: _toolKeys[c], icon: Icons.flash_on_rounded, label: M4JumperTightLines.tester, on: _tester != null, onTapUp: (_) => _useTester()),
        M4JumperTightControl.earth => _ToolButton(
            key: _toolKeys[c],
            icon: Icons.vertical_align_bottom_rounded,
            label: M4JumperTightLines.earth,
            on: _run.earthed,
            onTapUp: (d) => _earth(d.globalPosition)),
        M4JumperTightControl.brush => _ToolButton(
            key: _toolKeys[c],
            icon: Icons.brush_rounded,
            label: M4JumperTightLines.brush,
            on: _run.tool == M4JumperTightTool.brush,
            onTapUp: (_) => _hold(M4JumperTightTool.brush)),
        M4JumperTightControl.clamp => _ToolButton(
            key: _toolKeys[c],
            icon: Icons.link_rounded,
            label: M4JumperTightLines.clamp,
            on: _run.tool == M4JumperTightTool.clamp,
            onTapUp: (_) => _hold(M4JumperTightTool.clamp)),
        M4JumperTightControl.wrench => _ToolButton(
            key: _toolKeys[c],
            icon: Icons.build_rounded,
            label: M4JumperTightLines.wrench,
            on: _run.tool == M4JumperTightTool.wrench,
            onTapUp: (_) => _hold(M4JumperTightTool.wrench)),
      };

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_run.checked) return LinemanMode.cheer;
    if (_run.tool != M4JumperTightTool.none || _run.wrenchOn) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M4JumperTightRig get _rig {
    final s = _run.site;
    return M4JumperTightRig(
      kind: s.kind,
      phase: s.phase,
      end: s.end,
      live: _run.live,
      earthed: _run.earthed,
      cleaned: _run.cleaned,
      replaced: _run.replaced,
      fixed: _run.fixed,
      wrenchOn: _run.wrenchOn,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geo = M4JumperTightGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final s = _run.site;
    // Up the pole while he works (and at the deadly moment: the tool on the jumper).
    final up = (_run.up || _freeze) && !_run.checked;
    final box = up ? geo.upBox(s.phase, s.end) : geo.groundBox;
    final rig = _rig;
    final clampAt = geo.clamp(s.phase, s.end);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: AwakeClock(
            wake: _wake,
            quiet: quiet,
            builder: (context, t) => Stack(
              children: [
                Positioned.fill(
                  key: const ValueKey('pole'),
                  child: RepaintBoundary(child: CustomPaint(painter: M4JumperTightWorldPainter(geo: geo, rig: rig, t: t, seed: _run.index * 7 + 2))),
                ),
                Positioned.fromRect(
                  key: ValueKey('trainee-$up'),
                  rect: box,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
                if (up)
                  Positioned.fill(
                    key: const ValueKey('strap'),
                    child: IgnorePointer(child: CustomPaint(painter: M4JumperTightStrapPainter(box: box))),
                  ),
              ],
            ),
          ),
        ),
      ),
      // The spotted clamp, ringed until the recheck.
      if (_run.spotted && !_run.checked && !_freeze)
        Positioned.fromRect(
          key: const ValueKey('spotted'),
          rect: Rect.fromCenter(center: clampAt, width: 34, height: 34),
          child: const IgnorePointer(
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Color(0xFFFFE08A), width: 2.2)))),
          ),
        ),
      // The tester's lamp by the clamp.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: (clampAt.dx - 36).clamp(4.0, 280.0),
          top: clampAt.dy - 50,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_run.checked && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: (clampAt.dx - 70).clamp(8.0, 212.0),
          width: 140,
          top: clampAt.dy + 26,
          child: IgnorePointer(child: _StampPop(text: M4JumperTightLines.stampDone, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4JumperTightLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M4JumperTightArcPainter(at: clampAt, v: v)),
            ),
          ),
        ),
      // The next pole: a short fade from the last one.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('day-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 1, end: 0),
              duration: const Duration(milliseconds: 520),
              builder: (_, v, _) => v <= 0.001 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(5, 10, 22, v)),
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
    final handsOn = playing && !_run.checked && !deckUp && !coworkerOpen && _card == null;
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
              labels: M4JumperTightLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && _run.shutdown && !coworkerOpen)
                Positioned(
                  key: ValueKey('ptw-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: const IgnorePointer(child: _PtwChip()),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (playing && _card == null && _run.wrenchOn)
                Positioned(
                  key: const ValueKey('dial'),
                  right: 14,
                  top: pad.top + 150,
                  width: 150,
                  height: 104,
                  child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: M4JumperTightDialPainter(v: _torque, lo: kM4JumperTightLo, hi: kM4JumperTightHi)))),
                ),
              if (handsOn && _run.wrenchOn)
                Positioned(
                  key: const ValueKey('hud-torque'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: _HoldButton(key: _tightKey, label: M4JumperTightLines.tighten, progress: _torque, onDown: _press, onUp: _letGo),
                ),
              if (handsOn && _run.spotted && !_run.wrenchOn)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 2,
                  right: 2,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // Dealt in a fresh order each pole — never the work order.
                    children: [for (final c in _run.deal.toolsAt(_run.index)) _toolButton(c)],
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: !coworkerOnScreen || coworkerFromRight),
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
                  line: M4JumperTightLines.intro,
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

/// The permit in hand while the line is shut down.
class _PtwChip extends StatelessWidget {
  const _PtwChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E7D32), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 5),
          Text(M4JumperTightLines.ptw, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

class _TesterChip extends StatelessWidget {
  const _TesterChip({required this.live, required this.quiet});
  final bool live;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.7 + 0.3 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEE101A2B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: live ? SlmColors.danger : const Color(0xFF6E7C90), width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: live ? const Color(0xFFFF5A3D) : const Color(0xFF3A3F45),
                boxShadow: live ? const [BoxShadow(color: Color(0xAAFF5A3D), blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(live ? M4JumperTightLines.testerLive : M4JumperTightLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTapUp});
  final IconData icon;
  final String label;
  final bool on;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: on ? 2.4 : 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hold to turn the nut: the bar fills with the needle while held.
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.progress, required this.onDown, required this.onUp});
  final String label;
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
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: SlmColors.gold700),
                AnimatedBuilder(
                  animation: progress,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.value.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Color(0x55FFFFFF)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    const Icon(Icons.build_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(label, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
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
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SlmColors.success, width: 3),
        ),
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
