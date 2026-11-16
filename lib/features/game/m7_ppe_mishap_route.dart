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
import 'm7_ppe_mishap_route_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_ppe_mishap_route_world.dart' show M7PpeGeo, M7PpeItem, M7PpeKind, M7PpeSigns;

// Lesson 7.6 "ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন", কাজ 2 "ক্ষতি
// হলে কার কাছে?" (pack do_7_6_b, engineType m7_ppe_mishap_route). A roadside
// 11 kV work site in the morning. Three mishaps (dealt) happen to the
// trainee's PPE, each as a short wordless cutscene (gloves snag a bolt and
// tear; the helmet slips off the van roof, cracked or only dusty; a boot sole
// splits; the harness webbing nicks on a cross-arm edge; muddy but whole
// gloves come out of the bag). The item lands in his hands (a tap shows it
// close). The player carries it to the right hands:
//
//  সুপারভাইজার (damaged → right: report at once), সহকর্মী, হার্ডওয়্যার
//  দোকান, শুকনো কাপড় (dirty but whole → right: clean it), or the kit bag /
//  back on (keep using: right only for a dusty, undamaged helmet).
//
//  A report is answered (dealt): "ভ্যানে নতুন আছে, এই নাও।" (a spare with its
//  IS mark) or "নতুনটা কাল পাবে।". Then the record (pro tip 3): a hold of
//  ~0.6 s on the pocket diary writes today's date (from the docket), the item
//  and the person; never prompted, and a damage report with no record when the
//  work decision is made = slip 'রেকর্ড রাখুন' (once per mishap). The diary does
//  nothing when no report was made.
//  The work decision: drag the work pin onto "কাজ চালাই" or "এই কাজ আজ নয়" on the
//  docket and hold. Go in torn gloves / cut webbing with no spare = DEADLY;
//  with a cracked helmet or split sole and no spare = slip; stopping after a
//  good spare, or after a clean item, = slip (a needless stop).
//
// Deadly (module 7 table R10, R11, ruling M7-2/X3): torn gloves bagged or
// worked in; a harness with cut webbing bagged or worked in. Everything else
// is a slip. The coworker (X2/B1: listening = a slip here, taking PPE off is not
// on the deadly list): one push on a dealt mishap, before the work decision
// (the work pin is held for him). Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m7_ppe_mishap_route_world.dart), corner guide, a right step puts
// ◆ on the table → "কেন …?" → on; the coworker's two beats; gesture hands for
// how (a short generic upward drag from the item; a sweep over both docket
// marks and the pocket diary alike) — never what.

// ============================================================================
// Content
// ============================================================================

enum M7PpeStage { cut, route, decide, done }

/// Where the item is carried.
enum M7PpeDest { supervisor, coworker, shop, cloth, keep }

/// The work decision.
enum M7PpeWork { go, stop }

/// What a right step's reason asks about.
enum M7PpeWhy { report, clean, backOn, diary, stop, goNew }

abstract final class M7PpeMishapRouteLines {
  static const title = 'ক্ষতি হলে কার কাছে?';
  // DRAFT wording — owner (M7-10 / M6-12): every line below.
  static const intro = 'কাজের মাঝে PPE-র কিছু হলে কী করবেন? দায়িত্ব নিয়ে সামলান।';

  static const taskRoute = 'এটা নিয়ে কী করবেন?';
  static const taskDecide = 'এবার কাজের সিদ্ধান্ত নিন।';
  static String task(M7PpeStage s) => s == M7PpeStage.decide ? taskDecide : taskRoute;
  static const tasks = [taskRoute, taskDecide];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // The supervisor's answer (dealt). Silent captions in his bubble.
  static const replySpare = 'ভ্যানে নতুন আছে, এই নাও।';
  static const replyNone = 'নতুনটা কাল পাবে।';

  static String itemName(M7PpeItem i) => switch (i) {
        M7PpeItem.gloves => 'গ্লাভস',
        M7PpeItem.helmet => 'হেলমেট',
        M7PpeItem.boots => 'জুতো',
        M7PpeItem.harness => 'হারনেস',
      };
  static const closeHint = 'ছুঁয়ে বন্ধ করুন';
  static const supervisorLabel = 'সুপারভাইজার';
  static const coworkerLabel = 'সহকর্মী';
  static const sceneLabel = 'কাজের জায়গা';
  static const itemLabel = 'জিনিসটা';

  static const supervisorNames = ['রাজেশ', 'সুমন', 'অনিল', 'দেবাশিস'];
  static const coworkerNames = ['বিকাশ', 'মানিক', 'পলাশ', 'কার্তিক'];

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M7PpeWhy, String>{
    M7PpeWhy.report: 'কেন সঙ্গে সঙ্গে সুপারভাইজারকে বললেন?',
    M7PpeWhy.clean: 'কেন জিনিসটা পরিষ্কার করলেন?',
    M7PpeWhy.backOn: 'কেন হেলমেটটা আবার পরলেন?',
    M7PpeWhy.diary: 'কেন ডায়েরিতে লিখে রাখলেন?',
    M7PpeWhy.stop: 'কেন আজ এই কাজ করলেন না?',
    M7PpeWhy.goNew: 'কেন নতুনটা পরে কাজ চালালেন?',
  };
  static const whyRight = <M7PpeWhy, List<String>>{
    M7PpeWhy.report: ['ক্ষতি দেখলে অবিলম্বে সুপারভাইজারকে জানানো কর্মীর দায়িত্ব', 'ক্ষতিগ্রস্ত PPE বদলে দেওয়ার দায়িত্ব কোম্পানির, তাই জানাই'],
    M7PpeWhy.clean: ['PPE-এর যত্ন নেওয়া আর পরিষ্কার রাখা কর্মীর দায়িত্ব', 'কোম্পানির দেওয়া PPE পরিষ্কার রেখে ব্যবহার করাই নিয়ম'],
    M7PpeWhy.backOn: ['ক্ষতি নেই, তাই কোম্পানির দেওয়া PPE সবসময় ব্যবহার করি', 'ঠিক থাকা PPE সবসময় ঠিকমতো ব্যবহার করা কর্মীর দায়িত্ব'],
    M7PpeWhy.diary: ['বদলের রিপোর্ট করলে তারিখ আর কাকে বলেছি, রেকর্ড রাখি', 'রেকর্ড রাখা দরকার, তাই তারিখ আর নাম লিখে রাখলাম'],
    M7PpeWhy.stop: ['সঠিক PPE না থাকলে কাজ করতে অস্বীকার করার অধিকার আছে', 'আমার জীবন সবচেয়ে মূল্যবান, সঠিক PPE ছাড়া ঝুঁকির কাজ নয়'],
    M7PpeWhy.goNew: ['কোম্পানির দেওয়া নতুন IS-চিহ্নিত PPE পেয়ে কাজ চালালাম', 'ক্ষতিগ্রস্ত PPE বদলে সঠিক PPE নিয়েই কাজ করতে হয়'],
  };
  static const myths = [
    'বাজার থেকে সস্তার একটা কিনে নিলেই কাজ চলে যায়',
    'অভিজ্ঞ লোকের ছোটখাটো ক্ষতি নিয়ে ভাবার দরকার নেই',
    'সুপারভাইজার বিরক্ত হন, তাই চুপ করে থাকাই ভালো',
    'PPE-র ক্ষতি হলে নিজের টাকায় নতুন কিনে বদলে নিতে হয়',
    'কাজ আটকে গেলে নিজেরই বদনাম হয়, তাই চালিয়ে যেতে হয়',
    'এসব তো শুধু নতুনদের জন্য, অভিজ্ঞদের এসব লাগে না',
    'কেউ তো দেখছে না, তাই নিয়মে একটু ছাড় দেওয়া যায়',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play): lesson myth 2 word for word,
  // then 'তুইও খুলে রাখ।' (M7-10).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerLine = 'আমি অভিজ্ঞ, আমার PPE লাগে না। এটা শুধু নতুনদের জন্য। তুইও খুলে রাখ।';
  static const coworkerScript = CoworkerScript(
    line: coworkerLine,
    exitLine: coworkerExit,
    right: [
      'না — ঝুঁকির কাজে PPE সবার জন্য বাধ্যতামূলক, পরেই থাকব।',
      'না — অভিজ্ঞ হই বা নতুন, আইনে PPE সবার জন্য, খুলব না',
      'না — আইন অনুযায়ী ঝুঁকির কাজে সবাইকে PPE পরতে হয়',
    ],
    wrong: [
      'ঠিকই তো, অভিজ্ঞ হলে PPE নিয়ে একটু ছাড় চলতেই পারে',
      'আজ একবার PPE খুলে রাখি, কেউ তো আর দেখছে না এখন',
      'হ্যাঁ, পুরোনো লোকের পক্ষে PPE না পরলেও চলে যায়',
      'ঠিক আছে, তোর কথায় আমিও আমার হেলমেটটা খুলে রাখি',
      'আচ্ছা, কাজ তো অল্প, খুলে রেখেই সেরে ফেলি তাড়াতাড়ি',
    ],
    asks: ['কী করবেন?', 'ও বলছে PPE খুলে রাখতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const callHeld = 'ঠিক! ঝুঁকির কাজে PPE সবার জন্য বাধ্যতামূলক।';

  static const allSet = 'তিনটাই ঠিক হাতে গেল — PPE নিরাপদ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ক্ষতি হলে আগে সুপারভাইজার, তারপর রেকর্ড, তারপর কাজের সিদ্ধান্ত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'বেঁচে গেলেন — এবার সাবধান!';

  // "আজ যা ধরলেন".
  static const caughtReport = 'ক্ষতি হলে সুপারভাইজারকে';
  static const caughtClean = 'ময়লা হলে পরিষ্কার';
  static const caughtBackOn = 'ঠিক PPE আবার পরা';
  static const caughtDiary = 'ডায়েরিতে রেকর্ড';
  static const caughtGoNew = 'নতুন নিয়ে কাজ';
  static const caughtStop = 'PPE ছাড়া কাজ না';
  static const caughtGo = 'ঠিক PPE-তে কাজ';
  static const caughtNo = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new line (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [coworkerLine];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        ...whyQ.values,
        ...coworkerScript.asks.where((a) => !_oldAsks.contains(a)),
        callHeld,
        allSet,
        fail,
        deadlyWord,
        nearMissWord,
        for (final m in M7PpeMishapRouteMistakes.all) m.textBn,
      ];

  /// The supervisor's answers: silent captions in his bubble (listed for the
  /// owner's wording; not spoken).
  static const crewLines = [replySpare, replyNone];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M7PpeMishapRouteMistakes {
  static const _dir = 'assets/game/art/m7_ppe_mishap_route';

  // DRAFT wording — owner (M7-10 / M6-12). Lesson 7.6 points: 0 = employer's
  // duty (replace damaged PPE), 1 = worker's duty (use, care, report), 2 =
  // standards; the pro tips (record, refuse) have no point (null).
  static const wrongHands = DoMistake(
    key: '7.6/m7_ppe_mishap_route/wrong-hands',
    textBn: 'ক্ষতি দেখলে সঙ্গে সঙ্গে সুপারভাইজারকে জানাতে হয়। সহকর্মীকে দিলে বা শুধু মুছলে নতুন মেলে না।',
    art: '$_dir/wrong_hands.svg',
    lessonPoint: 1,
  );
  static const shopBuy = DoMistake(
    key: '7.6/m7_ppe_mishap_route/shop-buy',
    textBn: 'নিজের টাকায় দোকান থেকে PPE কেনা চলে না। ক্ষতি হলে সুপারভাইজারকে বলুন — বদলে দেওয়া কোম্পানির দায়িত্ব।',
    art: '$_dir/shop_buy.svg',
    lessonPoint: 0,
  );
  static const bagDamaged = DoMistake(
    key: '7.6/m7_ppe_mishap_route/bag-damaged',
    textBn: 'ফাটা হেলমেট বা ছেঁড়া জুতো ব্যাগে ভরে কাজে গেলে সুরক্ষা থাকে না। আগে সুপারভাইজারকে জানান।',
    art: '$_dir/bag_damaged.svg',
    lessonPoint: 1,
  );
  static const needlessReport = DoMistake(
    key: '7.6/m7_ppe_mishap_route/needless-report',
    textBn: 'এটা শুধু ধুলো বা কাদা, কোনো ক্ষতি নেই। পরিষ্কার করে ব্যবহার করুন — রিপোর্ট করার দরকার নেই।',
    art: '$_dir/needless_report.svg',
    lessonPoint: 1,
  );
  static const muddyGloves = DoMistake(
    key: '7.6/m7_ppe_mishap_route/muddy-gloves',
    textBn: 'কাদা মাখা গ্লাভস না মুছে পরবেন না। PPE-এর যত্ন নেওয়া আর পরিষ্কার রাখা কর্মীর দায়িত্ব।',
    art: '$_dir/muddy_gloves.svg',
    lessonPoint: 1,
  );
  static const noRecord = DoMistake(
    key: '7.6/m7_ppe_mishap_route/no-record',
    textBn: 'রেকর্ড রাখুন! বদলের জন্য রিপোর্ট করলে তারিখ আর কাকে বলেছেন, ডায়েরিতে লিখে রাখুন।',
    art: '$_dir/no_record.svg',
  );
  static const workNoSpare = DoMistake(
    key: '7.6/m7_ppe_mishap_route/work-no-spare',
    textBn: 'সঠিক PPE ছাড়া ঝুঁকির কাজ নয়। নতুন না পেলে কাজ করতে অস্বীকার করার অধিকার আপনার আছে।',
    art: '$_dir/work_no_spare.svg',
  );
  static const needlessStop = DoMistake(
    key: '7.6/m7_ppe_mishap_route/needless-stop',
    textBn: 'সঠিক PPE হাতে আছে, তাহলে কাজ থামানোর দরকার নেই। ঠিক PPE পরে কাজ চালান।',
    art: '$_dir/needless_stop.svg',
  );
  static const listen = DoMistake(
    key: '7.6/m7_ppe_mishap_route/listen',
    textBn: 'অভিজ্ঞ হলেও PPE খোলা চলে না। আইন বলে, ঝুঁকির কাজে প্রত্যেক কর্মীর জন্য PPE বাধ্যতামূলক।',
    art: '$_dir/listen.svg',
  );
  static const tornGlovesKept = DoMistake(
    key: '7.6/m7_ppe_mishap_route/torn-gloves-kept',
    textBn: 'ছেঁড়া গ্লাভস নিয়ে 11 kV লাইনে কাজ প্রাণঘাতী। রেটেড IS 4770 টাইপ 4 গ্লাভস ছাড়া কাজ নয়।',
    art: '$_dir/torn_gloves_kept.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const cutHarnessKept = DoMistake(
    key: '7.6/m7_ppe_mishap_route/cut-harness-kept',
    textBn: 'কাটা বা ছেঁড়া ফিতার হারনেস নিয়ে কাজ করা প্রাণঘাতী। বদলে নতুন না পেলে কাজ নয়।',
    art: '$_dir/cut_harness_kept.svg',
    deadly: true,
    lessonPoint: 0,
  );

  static const List<DoMistake> all = [
    wrongHands,
    shopBuy,
    bagDamaged,
    needlessReport,
    muddyGloves,
    noRecord,
    workNoSpare,
    needlessStop,
    listen,
    tornGlovesKept,
    cutHarnessKept,
  ];

  /// The deadly ones (the catalog's deadlyRules).
  static List<String> get deadlyKeys => [for (final m in all) if (m.deadly) m.key];
}

/// One mishap of the three.
@immutable
class M7PpeIncident {
  const M7PpeIncident(this.kind, {this.spare = false});
  final M7PpeKind kind;

  /// The supervisor has a new one in the van (only for a damaged item).
  final bool spare;
}

@immutable
class M7PpeDeal {
  const M7PpeDeal({
    required this.incidents,
    required this.coworkerAt,
    required this.supervisorName,
    required this.coworkerName,
    required this.badgeRight,
    required this.date,
  });

  final List<M7PpeIncident> incidents;

  /// The mishap before whose work decision he comes.
  final int coworkerAt;
  final String supervisorName;
  final String coworkerName;
  final bool badgeRight;

  /// Today's date on the docket, dd/mm (English digits).
  final String date;

  int get damages => incidents.where((i) => i.kind.damaged).length;
}

M7PpeDeal m7PpeDeal(math.Random rng) {
  final items = List<M7PpeItem>.of(M7PpeItem.values)..shuffle(rng);
  final three = items.take(3).toList();
  // One clean mishap (muddy gloves or a dusty helmet) in three plays of four.
  final cleanable = [for (final i in three) if (i == M7PpeItem.gloves || i == M7PpeItem.helmet) i];
  final clean = rng.nextInt(4) == 0 ? null : cleanable[rng.nextInt(cleanable.length)];
  final incidents = <M7PpeIncident>[
    for (final i in three)
      if (i == clean)
        M7PpeIncident(i == M7PpeItem.gloves ? M7PpeKind.glovesMuddy : M7PpeKind.helmetDusty)
      else
        M7PpeIncident(
          switch (i) {
            M7PpeItem.gloves => M7PpeKind.glovesTorn,
            M7PpeItem.helmet => M7PpeKind.helmetCracked,
            M7PpeItem.boots => M7PpeKind.bootSplit,
            M7PpeItem.harness => M7PpeKind.harnessNicked,
          },
          spare: rng.nextInt(100) < 55,
        ),
  ];
  return M7PpeDeal(
    incidents: incidents,
    coworkerAt: rng.nextInt(3),
    supervisorName: M7PpeMishapRouteLines.supervisorNames[rng.nextInt(M7PpeMishapRouteLines.supervisorNames.length)],
    coworkerName: M7PpeMishapRouteLines.coworkerNames[rng.nextInt(M7PpeMishapRouteLines.coworkerNames.length)],
    badgeRight: rng.nextBool(),
    date: '${1 + rng.nextInt(28)}/${1 + rng.nextInt(12)}',
  );
}

typedef _M = M7PpeMishapRouteMistakes;

/// What a step did.
enum M7PpeStepKind { stay, slip, deadly, right, rightDone }

@immutable
class M7PpeStep {
  const M7PpeStep(this.kind, {this.mistake});
  final M7PpeStepKind kind;
  final DoMistake? mistake;
}

/// What the end of a reason leads to.
enum M7PpePaid { toDecide, stayDecide, nextIncident, done }

/// The "আজ যা ধরলেন" tags (one place, so the run needs no page).
abstract final class M7PpeTags {
  static const report = M7PpeMishapRouteLines.caughtReport;
  static const clean = M7PpeMishapRouteLines.caughtClean;
  static const backOn = M7PpeMishapRouteLines.caughtBackOn;
  static const diary = M7PpeMishapRouteLines.caughtDiary;
  static const goNew = M7PpeMishapRouteLines.caughtGoNew;
  static const stop = M7PpeMishapRouteLines.caughtStop;
  static const go = M7PpeMishapRouteLines.caughtGo;
}

/// The play state (pure logic).
class M7PpeRun {
  M7PpeRun(this.deal);
  final M7PpeDeal deal;

  int index = 0;
  var stage = M7PpeStage.cut;
  int slips = 0;
  int stepSlips = 0;
  final List<String> caught = [];

  /// A right step is in; its reason comes next.
  var roundDone = false;
  M7PpeWhy? why;

  /// A deadly act ends the play.
  DoMistake? deadly;

  // This mishap.
  var reported = false;
  var recorded = false;
  var recordSlipped = false;
  var cleaned = false;
  String? replyLine;

  /// The diary's line, once written (set by the page).
  String? note;

  /// The first record's reason is asked once a play.
  var _diaryAsked = false;

  /// Where each mishap went (for the pass panel).
  final List<String> routes = [];

  bool get done => stage == M7PpeStage.done;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => stepSlips == 0;

  M7PpeIncident get incident => deal.incidents[index.clamp(0, deal.incidents.length - 1)];
  M7PpeKind get kind => incident.kind;

  /// A spare is in his hands (after the report).
  bool get spareInHand => reported && incident.spare;

  /// Proper PPE is on him now (an undamaged item, or the spare).
  bool get safeNow => !kind.damaged || spareInHand;

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  M7PpeStep _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return M7PpeStep(M7PpeStepKind.slip, mistake: m);
  }

  M7PpeStep _die(DoMistake m) {
    deadly = m;
    return M7PpeStep(M7PpeStepKind.deadly, mistake: m);
  }

  M7PpeStep _right(M7PpeWhy w) {
    roundDone = true;
    why = w;
    return const M7PpeStep(M7PpeStepKind.right);
  }

  void _advance() {
    index++;
    reported = recorded = recordSlipped = cleaned = false;
    replyLine = null;
    note = null;
    stage = index >= deal.incidents.length ? M7PpeStage.done : M7PpeStage.cut;
  }

  /// The cutscene is over: the item is in his hands.
  void cutDone() {
    if (stage == M7PpeStage.cut) stage = M7PpeStage.route;
  }

  /// The item dropped on a place.
  M7PpeStep route(M7PpeDest d) {
    if (stage != M7PpeStage.route || roundDone || ended) return const M7PpeStep(M7PpeStepKind.stay);
    final k = kind;
    if (k.damaged) {
      switch (d) {
        case M7PpeDest.supervisor:
          reported = true;
          _tag(M7PpeTags.report);
          routes.add('${M7PpeMishapRouteLines.itemName(k.item)} → ${M7PpeMishapRouteLines.supervisorLabel}');
          return _right(M7PpeWhy.report);
        case M7PpeDest.coworker || M7PpeDest.cloth:
          return _slip(_M.wrongHands);
        case M7PpeDest.shop:
          return _slip(_M.shopBuy);
        case M7PpeDest.keep:
          if (k.deadlyIfKept) return _die(k.item == M7PpeItem.gloves ? _M.tornGlovesKept : _M.cutHarnessKept);
          return _slip(_M.bagDamaged);
      }
    }
    switch (d) {
      case M7PpeDest.cloth:
        cleaned = true;
        _tag(M7PpeTags.clean);
        return _right(M7PpeWhy.clean);
      case M7PpeDest.keep:
        if (k == M7PpeKind.glovesMuddy) return _slip(_M.muddyGloves);
        _tag(M7PpeTags.backOn);
        return _right(M7PpeWhy.backOn);
      case M7PpeDest.supervisor || M7PpeDest.coworker || M7PpeDest.shop:
        return _slip(_M.needlessReport);
    }
  }

  /// A hold on the diary: writes the line after a report (else nothing).
  /// Null when nothing happened; a right step with a reason the first time.
  M7PpeStep? record() {
    if (stage != M7PpeStage.decide || roundDone || ended || !reported || recorded) return null;
    recorded = true;
    _tag(M7PpeTags.diary);
    if (_diaryAsked) return const M7PpeStep(M7PpeStepKind.rightDone);
    _diaryAsked = true;
    return _right(M7PpeWhy.diary);
  }

  /// The work pin held on a docket mark.
  M7PpeStep decide(M7PpeWork w) {
    if (stage != M7PpeStage.decide || roundDone || ended) return const M7PpeStep(M7PpeStepKind.stay);
    final k = kind;
    final goes = w == M7PpeWork.go;
    if (goes && !safeNow) {
      if (k.deadlyIfKept) return _die(k.item == M7PpeItem.gloves ? _M.tornGlovesKept : _M.cutHarnessKept);
      return _slip(_M.workNoSpare);
    }
    if (!goes && safeNow) return _slip(_M.needlessStop);
    // A correct decision: after a report, the record must be in (once).
    if (reported && !recorded && !recordSlipped) {
      recordSlipped = true;
      return _slip(_M.noRecord);
    }
    if (k.damaged) {
      _tag(goes ? M7PpeTags.goNew : M7PpeTags.stop);
      return _right(goes ? M7PpeWhy.goNew : M7PpeWhy.stop);
    }
    _tag(M7PpeTags.go);
    _advance();
    return const M7PpeStep(M7PpeStepKind.rightDone);
  }

  /// The reason is paid.
  M7PpePaid paid() {
    final w = why;
    roundDone = false;
    why = null;
    stepSlips = 0;
    switch (w) {
      case M7PpeWhy.report || M7PpeWhy.clean || M7PpeWhy.backOn:
        stage = M7PpeStage.decide;
        if (w == M7PpeWhy.report) replyLine = incident.spare ? M7PpeMishapRouteLines.replySpare : M7PpeMishapRouteLines.replyNone;
        return M7PpePaid.toDecide;
      case M7PpeWhy.diary:
        return M7PpePaid.stayDecide;
      case M7PpeWhy.stop || M7PpeWhy.goNew:
        _advance();
        return done ? M7PpePaid.done : M7PpePaid.nextIncident;
      case null:
        return M7PpePaid.stayDecide;
    }
  }

  /// The play moved on after a clean mishap's decision (no reason).
  M7PpePaid afterAdvance() => done ? M7PpePaid.done : M7PpePaid.nextIncident;

  /// Listened to him (a slip here: taking PPE off is not on the deadly list).
  DoMistake listen() {
    slips++;
    stepSlips++;
    return M7PpeMishapRouteMistakes.listen;
  }
}

/// The cutscene, the hold on the diary / the pin.
const kM7CutMs = 1500;
const kM7HoldMs = 600;

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   three cutscenes 4500 · three routes ≈ 4500 · a reason each (~8200 × 3)
///   · two decisions on damaged items (hold + reason ≈ 9700 × 2) · one clean
///   decision ≈ 2000 · the diary (hold + reason) ≈ 9700 · the coworker ≈ 9600
///   ≈ 74000 · 85 % ≈ 62000 → 60 s (a builder's estimate; owner may tune
///   after playtest).
const m7PpeMishapRouteQuickMs = 60000;

@immutable
class M7PpeMishapRoutePack {
  const M7PpeMishapRoutePack({required this.id, required this.titleBn, this.quickMs = m7PpeMishapRouteQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7PpeMishapRoutePack> m7PpeMishapRoutePacks = {
  'do_7_6_b': M7PpeMishapRoutePack(id: 'do_7_6_b', titleBn: M7PpeMishapRouteLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7PpeMishapRouteProbe {
  static M7PpeRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7PpeMishapRoutePage extends StatefulWidget {
  const M7PpeMishapRoutePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7PpeMishapRoutePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7PpeMishapRoutePage> createState() => _M7PpeMishapRoutePageState();
}

class _M7PpeMishapRoutePageState extends State<M7PpeMishapRoutePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _PpeRunPage(
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

class _PpeRunPage extends ConsumerStatefulWidget {
  const _PpeRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7PpeMishapRoutePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_PpeRunPage> createState() => _PpeRunPageState();
}

class _PpeRunPageState extends ConsumerState<_PpeRunPage> with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7PpeRun _run;
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

  /// The cutscene of this mishap, and the timer that ends it.
  int _cutN = 0;
  Timer? _cutTimer;

  /// The item in hand: its drag position (centre) and the grab offset.
  Offset? _itemAt;
  Offset _itemGrab = Offset.zero;

  /// The work pin: its drag position, the mark it is over and the hold.
  Offset? _pinAt;
  Offset _pinGrab = Offset.zero;
  M7PpeWork? _pinOver;

  /// A hold under way (the diary or the pin on a mark) and its count.
  Timer? _holdTimer;
  String? _holding;
  int _holdN = 0;

  var _closeUp = false;
  var _freeze = false;
  Completer<void>? _frozen;
  Offset _flashAt = Offset.zero;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _goKey = GlobalKey();
  final _stopKey = GlobalKey();
  final _diaryKey = GlobalKey();
  int _steps = 0;
  M7PpeGeo? _geoNow;

  @override
  LevelContext get deathCtx => widget.ctx;

  @override
  void initState() {
    super.initState();
    _run = M7PpeRun(m7PpeDeal(widget.rng));
    M7PpeMishapRouteProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M7PpeDeal get _deal => _run.deal;

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _cutTimer?.cancel();
    _holdTimer?.cancel();
    if (identical(M7PpeMishapRouteProbe.run, _run)) M7PpeMishapRouteProbe.run = null;
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
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_closeUp && _run.stage != M7PpeStage.cut;

  String get _task => M7PpeMishapRouteLines.task(_run.stage);

  Offset get _centre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  void _stepDone() {
    _steps++;
    setState(() {});
  }

  /// His window: once he is due, the decisive control waits for him.
  bool _waitForHim() => coworkerDue && holdForCoworker();

  // --- a mishap ------------------------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    _beginIncident();
  }

  void _beginIncident() {
    _hush();
    _cutN++;
    setState(() {
      _itemAt = null;
      _pinAt = null;
      _closeUp = false;
    });
    _cutTimer?.cancel();
    _cutTimer = Timer(Duration(milliseconds: _quiet ? 300 : kM7CutMs), _cutOver);
    _cue('sounds/intro/click.ogg', volume: 0.4);
  }

  void _cutOver() {
    if (!mounted || _ended) return;
    _run.cutDone();
    _steps++;
    setState(() {});
    if (!tableBusy) unawaited(_sayChain([_task]));
  }

  // --- the item: carried to a place ------------------------------------------------
  void _panStart(Offset p, M7PpeGeo geo) {
    _itemAt = null;
    _pinAt = null;
    _pinOver = null;
    if (!_canPlay) return;
    if (_run.stage == M7PpeStage.route) {
      if (!geo.itemGrab.inflate(8).contains(p)) return;
      _itemGrab = geo.hand - p;
      setState(() => _itemAt = geo.hand);
    } else if (_run.stage == M7PpeStage.decide) {
      if ((p - M7PpeGeo.pinHome).distance > M7PpeGeo.pinGrabR) return;
      if (_waitForHim()) return;
      _pinGrab = M7PpeGeo.pinHome - p;
      setState(() => _pinAt = M7PpeGeo.pinHome);
    }
  }

  void _panUpdate(Offset p) {
    if (_itemAt != null) {
      if (!_canPlay) {
        setState(() => _itemAt = null);
        return;
      }
      final q = p + _itemGrab;
      setState(() => _itemAt = Offset(q.dx.clamp(20.0, 340.0), q.dy.clamp(110.0, (_geoNow?.bottom ?? 800) - 20)));
    } else if (_pinAt != null) {
      if (!_canPlay) {
        _cancelHold();
        setState(() => _pinAt = null);
        return;
      }
      final q = p + _pinGrab;
      final at = Offset(q.dx.clamp(14.0, 346.0), q.dy.clamp(110.0, (_geoNow?.bottom ?? 800) - 20));
      final over = _markAt(at);
      setState(() => _pinAt = at);
      if (over != _pinOver) {
        _pinOver = over;
        _cancelHold();
        if (over != null) _holdStart(over == M7PpeWork.go ? 'go' : 'stop');
      }
    }
  }

  M7PpeWork? _markAt(Offset p) {
    if (M7PpeGeo.goMark.inflate(6).contains(p)) return M7PpeWork.go;
    if (M7PpeGeo.stopMark.inflate(6).contains(p)) return M7PpeWork.stop;
    return null;
  }

  void _panEnd(Offset global) {
    final at = _itemAt;
    if (at != null) {
      final geo = _geoNow;
      setState(() => _itemAt = null);
      if (geo == null || !_canPlay) return;
      final d = _destAt(at, geo);
      if (d == null) return;
      _drop(d, global);
      return;
    }
    if (_pinAt != null) {
      _cancelHold();
      setState(() {
        _pinAt = null;
        _pinOver = null;
      });
    }
  }

  void _panCancel() {
    if (_itemAt != null) setState(() => _itemAt = null);
    if (_pinAt != null) {
      _cancelHold();
      setState(() {
        _pinAt = null;
        _pinOver = null;
      });
    }
  }

  M7PpeDest? _destAt(Offset p, M7PpeGeo geo) {
    if (M7PpeGeo.supervisor.contains(p)) return M7PpeDest.supervisor;
    if (M7PpeGeo.coworker.contains(p)) return M7PpeDest.coworker;
    if (M7PpeGeo.shop.contains(p)) return M7PpeDest.shop;
    if (M7PpeGeo.cloth.contains(p)) return M7PpeDest.cloth;
    if (geo.keepAt(p)) return M7PpeDest.keep;
    return null;
  }

  void _drop(M7PpeDest d, Offset global) {
    final r = _run.route(d);
    switch (r.kind) {
      case M7PpeStepKind.stay:
        return;
      case M7PpeStepKind.slip:
        _stepDone();
        unawaited(_mistake(r.mistake!, global));
      case M7PpeStepKind.deadly:
        unawaited(_deadly(r.mistake!));
      case M7PpeStepKind.right || M7PpeStepKind.rightDone:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
        _stepDone();
        _askStep();
    }
  }

  // --- the diary and the pin: holds --------------------------------------------------
  void _holdStart(String what) {
    if (!_canPlay || _holdTimer != null || _run.stage != M7PpeStage.decide) return;
    if (what == 'diary' && (!_run.reported || _run.recorded)) {
      _tick();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _holding = what;
      _holdN++;
      _holdTimer = Timer(const Duration(milliseconds: kM7HoldMs), () {
        _holdTimer = null;
        _holding = null;
        if (!mounted) return;
        switch (what) {
          case 'diary':
            _writeRecord();
          default:
            _commitPin(what == 'go' ? M7PpeWork.go : M7PpeWork.stop);
        }
      });
    });
  }

  void _cancelHold() {
    if (_holdTimer == null) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    if (mounted) setState(() => _holding = null);
  }

  String get _noteLine => '${_deal.date} · ${M7PpeMishapRouteLines.itemName(_run.kind.item)} · ${M7PpeMishapRouteLines.supervisorLabel} ${_deal.supervisorName}';

  void _writeRecord() {
    if (!_canPlay) return;
    final r = _run.record();
    if (r == null) return;
    _run.note = _noteLine;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/card_deal_a.ogg', volume: 0.6);
    _stepDone();
    if (r.kind == M7PpeStepKind.right) {
      _askStep(amount: 10);
    } else {
      unawaited(_levelDelta(5, _centre, mood: GuideMood.glad));
    }
  }

  void _commitPin(M7PpeWork w) {
    final over = _pinOver;
    setState(() {
      _pinAt = null;
      _pinOver = null;
    });
    if (over != w || !_canPlay) return;
    final r = _run.decide(w);
    switch (r.kind) {
      case M7PpeStepKind.stay:
        return;
      case M7PpeStepKind.slip:
        _stepDone();
        unawaited(_mistake(r.mistake!, _centre));
      case M7PpeStepKind.deadly:
        unawaited(_deadly(r.mistake!));
      case M7PpeStepKind.right:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        _askStep();
      case M7PpeStepKind.rightDone:
        HapticFeedback.mediumImpact();
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        _stepDone();
        unawaited(_levelDelta(10, _centre, mood: GuideMood.glad));
        unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
          if (!mounted || _ended) return;
          _afterPaid(_run.afterAdvance());
        }));
    }
  }

  // --- the success beat ---------------------------------------------------------------
  void _askStep({int? amount}) {
    final w = _run.why;
    if (w == null) return;
    _hush();
    putOnTable(amount ?? (15 + (_run.thorough ? 5 : 0)));
    final s = _steps;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M7PpeMishapRouteLines.whyRight[w]!, M7PpeMishapRouteLines.myths, widget.rng),
      question: M7PpeMishapRouteLines.whyQ[w]!,
      stillValid: () => !_ended && _run.index == idx && _steps == s,
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
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 400 : 900), () {
      if (!mounted || _ended) return;
      _afterPaid(_run.paid());
    }));
  }

  void _afterPaid(M7PpePaid p) {
    setState(() {});
    switch (p) {
      case M7PpePaid.toDecide:
        // He comes on one dealt mishap, before its work decision.
        if (_run.index == _deal.coworkerAt && !coworkerDone && !coworkerDue) scheduleCoworker();
        unawaited(_sayChain([_task]));
      case M7PpePaid.stayDecide:
        unawaited(_sayChain([_task]));
      case M7PpePaid.nextIncident:
        _beginIncident();
      case M7PpePaid.done:
        unawaited(_finish());
    }
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  // --- the pressure moment -----------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => M7PpeMishapRouteLines.coworkerScript;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final window = _run.stage == M7PpeStage.decide && _run.index == _deal.coworkerAt && !_run.roundDone;
    if (!window) return null;
    if (_intro || _card != null || tableBusy || _freeze || _closeUp || _pinAt != null || _holdTimer != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      final m = _run.listen();
      setState(() {});
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7PpeMishapRouteLines.caughtNo);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7PpeMishapRouteLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended || _freeze) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7PpeMishapRouteLines.tapWhy[_nudgeN++ % M7PpeMishapRouteLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _cutTimer?.cancel();
    _cancelHold();
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
    _cancelHold();
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _itemAt = null;
      _pinAt = null;
      _pinOver = null;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7ppemishap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Torn gloves or cut webbing in use: the scene freezes grey and the arc
  /// flashes in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _cutTimer?.cancel();
    _cancelHold();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final geo = _geoNow;
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _itemAt = null;
      _pinAt = null;
      _pinOver = null;
      _flashAt = geo == null ? const Offset(240, 440) : geo.hand;
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
    final speak = await SpokenOnce.first('m7ppemishap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M7PpeMishapRouteLines.deadlyWord : M7PpeMishapRouteLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
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
    final centre = _centre;
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
    await _say(!_run.passed ? M7PpeMishapRouteLines.fail : (_quickBonus ? M7PpeMishapRouteLines.quick : M7PpeMishapRouteLines.allSet),
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

  // --- the gesture hand -----------------------------------------------------------
  /// How to touch, never what: a short generic upward drag from the item in
  /// hand (toward no person and no place); on the work decision a sweep over
  /// both docket marks and the pocket diary alike (the diary is in the sweep
  /// on every decision, report or not).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    if (_run.stage == M7PpeStage.route) {
      return HintSpec.drag(geo.hand, toward: const Offset(0, -1), travel: 60, space: HintSpace.scene);
    }
    if (_run.stage == M7PpeStage.decide) return HintSpec.sweepOver([_goKey, _stopKey, _diaryKey]);
    return null;
  }

  // --- the scene --------------------------------------------------------------------
  /// The item as the hands hold it now (null: nothing in hand).
  Widget? _itemWidget(M7PpeGeo geo) {
    final r = _run;
    if (r.stage == M7PpeStage.done) return null;
    final k = r.kind;
    final inCut = r.stage == M7PpeStage.cut;
    final hide = r.stage == M7PpeStage.decide && k.damaged && !r.spareInHand;
    if (hide) return null;
    final spare = r.stage == M7PpeStage.decide && r.spareInHand;
    final at = _itemAt ?? geo.hand;
    final box = Rect.fromCenter(center: at, width: 64, height: 64);
    final painter = M7ItemPainter(kind: k, spare: spare, clean: r.cleaned);
    final label = M7PpeMishapRouteLines.itemLabel;
    final item = Semantics(label: label, child: RepaintBoundary(child: CustomPaint(painter: painter)));
    if (inCut && !_quiet) {
      // The mishap: where it falls from (a helmet from the van roof; the rest
      // from the hands or the bag), then it lands in his hands.
      final from = switch (k.item) {
        M7PpeItem.helmet => const Offset(150, 120),
        M7PpeItem.gloves => k == M7PpeKind.glovesMuddy ? geo.bag.center : geo.hand + const Offset(-50, -40),
        M7PpeItem.boots => geo.hand + const Offset(-60, 40),
        M7PpeItem.harness => geo.hand + const Offset(-50, -20),
      };
      return Positioned.fill(
        key: const ValueKey('item'),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('cut-$_cutN'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: kM7CutMs - 200),
            curve: Curves.easeInOut,
            builder: (_, v, child) {
              final p = Offset.lerp(from, geo.hand, v)!;
              final hop = k.item == M7PpeItem.helmet ? 0.0 : -math.sin(v * math.pi) * 18;
              return Stack(children: [Positioned.fromRect(rect: Rect.fromCenter(center: p.translate(0, hop), width: 64, height: 64), child: child!)]);
            },
            child: item,
          ),
        ),
      );
    }
    return Positioned.fromRect(
      key: const ValueKey('item'),
      rect: box,
      child: item,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7PpeGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final r = _run;
    final deciding = r.stage == M7PpeStage.decide;
    final itemW = _itemWidget(geo);
    final pinAt = _pinAt ?? M7PpeGeo.pinHome;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('scenery'),
                child: RepaintBoundary(child: CustomPaint(painter: M7PpeSceneryPainter(geo: geo, date: _deal.date))),
              ),
              // People.
              Positioned.fromRect(
                key: const ValueKey('supervisor'),
                rect: const Rect.fromLTWH(268, 214, 48, 77),
                child: Semantics(
                  label: '${M7PpeMishapRouteLines.supervisorLabel} ${_deal.supervisorName}',
                  child: CustomPaint(painter: M7PpePersonPainter(role: M7PpeRole.supervisor, name: _deal.supervisorName, badgeRight: _deal.badgeRight)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('coworker-fig'),
                rect: const Rect.fromLTWH(126, 236, 44, 70),
                child: Semantics(
                  label: '${M7PpeMishapRouteLines.coworkerLabel} ${_deal.coworkerName}',
                  child: CustomPaint(painter: M7PpePersonPainter(role: M7PpeRole.coworker, name: _deal.coworkerName, badgeRight: !_deal.badgeRight)),
                ),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: Rect.fromLTWH(geo.trainee.dx - 28, geo.trainee.dy - 87, 56, 90),
                child: const CustomPaint(painter: M7PpePersonPainter(role: M7PpeRole.trainee)),
              ),
              // The docket's two marks.
              Positioned.fromRect(
                key: const ValueKey('mark-go'),
                rect: M7PpeGeo.goMark,
                child: _Mark(key: _goKey, label: M7PpeSigns.go, over: _pinOver == M7PpeWork.go, holding: _holding == 'go', holdN: _holdN, quiet: quiet),
              ),
              Positioned.fromRect(
                key: const ValueKey('mark-stop'),
                rect: M7PpeGeo.stopMark,
                child: _Mark(key: _stopKey, label: M7PpeSigns.stop, over: _pinOver == M7PpeWork.stop, holding: _holding == 'stop', holdN: _holdN, quiet: quiet),
              ),
              // The work pin.
              Positioned.fromRect(
                key: const ValueKey('pin'),
                rect: Rect.fromCenter(center: pinAt, width: 34, height: 34),
                child: Semantics(label: M7PpeSigns.pin, child: IgnorePointer(child: CustomPaint(painter: M7PinPainter(lifted: _pinAt != null)))),
              ),
              // The diary in his shirt pocket (a scene object, never prompted).
              Positioned.fromRect(
                key: const ValueKey('diary'),
                rect: geo.diary,
                child: Semantics(
                  label: M7PpeSigns.diary,
                  child: Stack(
                    key: _diaryKey,
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: M7DiaryPainter(written: r.note != null, holding: _holding == 'diary')),
                      if (_holding == 'diary')
                        Center(
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: quiet
                                ? const CircularProgressIndicator(value: 0.6, strokeWidth: 4, color: Color(0xFF9BE7A9))
                                : TweenAnimationBuilder<double>(
                                    key: ValueKey('diary-$_holdN'),
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: kM7HoldMs),
                                    builder: (_, v, _) => CircularProgressIndicator(value: v, strokeWidth: 4, color: const Color(0xFF9BE7A9)),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (r.note != null && deciding)
                Positioned.fromRect(
                  key: const ValueKey('note'),
                  rect: Rect.fromLTWH(96, geo.feetY - 148, 168, 36),
                  child: _Note(text: r.note!),
                ),
              if (r.replyLine != null && deciding)
                Positioned.fromRect(
                  key: const ValueKey('reply'),
                  rect: M7PpeGeo.reply,
                  child: _Bubble(text: r.replyLine!),
                ),
              ?itemW,
              Positioned.fill(
                key: const ValueKey('touch'),
                child: Semantics(
                  label: M7PpeMishapRouteLines.sceneLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onTapUp: (d) {
                      if (_canPlay && (r.stage == M7PpeStage.route || deciding) && geo.itemGrab.inflate(6).contains(d.localPosition) && itemW != null) {
                        _tick();
                        setState(() => _closeUp = true);
                        return;
                      }
                      _hints.missTap();
                    },
                    onPanStart: (d) => _panStart(d.localPosition, geo),
                    onPanUpdate: (d) => _panUpdate(d.localPosition),
                    onPanEnd: (d) => _panEnd(d.globalPosition),
                    onPanCancel: _panCancel,
                  ),
                ),
              ),
              // The diary's hold (over the touch layer).
              Positioned.fromRect(
                key: const ValueKey('diary-hold'),
                rect: geo.diary,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _holdStart('diary'),
                  onTapUp: (_) => _cancelHold(),
                  onTapCancel: _cancelHold,
                ),
              ),
            ],
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
              builder: (_, v, _) => CustomPaint(painter: M7FlashPainter(at: _flashAt, v: v)),
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final waiting = handsOn &&
        !tableBusy &&
        !_closeUp &&
        _itemAt == null &&
        _pinAt == null &&
        _holdTimer == null &&
        (_run.stage == M7PpeStage.route || _run.stage == M7PpeStage.decide);
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
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.index}/${_run.stage.name}/$_steps',
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_closeUp && playing)
                Positioned.fill(
                  key: const ValueKey('closeup'),
                  child: _CloseUp(
                    kind: _run.kind,
                    spare: _run.stage == M7PpeStage.decide && _run.spareInHand,
                    clean: _run.cleaned,
                    onClose: () => setState(() => _closeUp = false),
                  ),
                ),
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
                  line: M7PpeMishapRouteLines.intro,
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

/// One of the docket's two marks (the work pin is dropped and held on it).
class _Mark extends StatelessWidget {
  const _Mark({super.key, required this.label, required this.over, required this.holding, required this.holdN, required this.quiet});
  final String label;
  final bool over;
  final bool holding;
  final int holdN;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF4ECD6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: over ? const Color(0xFF1E88E5) : const Color(0xFF8A6A3C), width: over ? 2.4 : 1.4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF2A2018))),
                ),
              ),
            ),
          ),
          if (holding)
            Positioned.fill(
              child: IgnorePointer(
                child: quiet
                    ? const ColoredBox(color: Color(0x331E88E5))
                    : TweenAnimationBuilder<double>(
                        key: ValueKey('mark-$holdN'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: kM7HoldMs),
                        builder: (_, v, _) => FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: v, child: const ColoredBox(color: Color(0x331E88E5))),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The supervisor's answer (a speech bubble by him).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        label: text,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5D4037), width: 1.6),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Center(child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018), height: 1.2))),
          ),
        ),
      ),
    );
  }
}

/// The line the diary wrote (a page held up beside it).
class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        label: text,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF4),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF8A6A3C), width: 1.4),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Center(child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1F3B8A), height: 1.2))),
          ),
        ),
      ),
    );
  }
}

/// A tap on the item: a big look at it (a tap anywhere closes it).
class _CloseUp extends StatelessWidget {
  const _CloseUp({required this.kind, required this.spare, required this.clean, required this.onClose});
  final M7PpeKind kind;
  final bool spare;
  final bool clean;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        color: const Color(0xCC050A16),
        child: Center(
          child: Semantics(
            label: M7PpeMishapRouteLines.itemName(kind.item),
            child: SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(painter: M7ItemPainter(kind: kind, spare: spare, clean: clean, labels: true)),
            ),
          ),
        ),
      ),
    );
  }
}
