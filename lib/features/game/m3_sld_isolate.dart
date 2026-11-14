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
import 'm3_sld_isolate_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_sld_isolate_world.dart' show M3SldIsolateKind, M3SldIsolatePoint;

// Lesson 3.10 "লাইন ডায়াগ্রাম পড়া: কাগজের ওপর জাদুর নকশা", কাজ
// "ম্যাপ দেখে বিচ্ছিন্ন" (pack do_3_10_a, engineType m3_sld_isolate). Three
// shutdown dockets a play. For each, the trainee reads the area's SLD on the
// field tablet (source on top → load below), finds every point that must be
// opened to make the docket's section dead, opens them in a safe order, and
// still proves the section dead with a tester before the work.
//
// The lesson's rules, and only those:
//   • point 1 (SLD): a tool to plan the isolation of an area;
//   • point 2 (symbols): CB = a small box, isolator / AB switch = a line with a
//     break, DO fuse, transformer = two coils not touching; safety tip: know
//     an isolator from a breaker — an isolator is never opened on load;
//   • point 3 (reading it): the feeder's name and number identify it; NO / NC
//     points are marked; before work, mark the area and its isolation points
//     on the diagram;
//   • pro tip 1: read top (source) → bottom (load); pro tip 4: the digital
//     SLD shows ON/OFF in colour;
//   • myth 1: "I know this area like my palm" — in a ring / interconnected
//     feeder the power can come from the other side (backfeed);
//   • the film (3.10 line 15): the digital SLD shows live or dead, still test
//     with a tester before the work.
// From the module's safety rules (NOT lesson 3.10's text — flagged in
// REGISTER.md): the tag on every point opened, a lock-and-tag on the NO point
// so nobody closes it, and the earth after proving dead.
//
// Hands on: tap a CB / AB on the tablet's SLD to open it (it turns green and
// gets a tag; the NO tie gets its tag) · টেস্টার · আর্থ · কাজ শুরু.
//
// Deadly: an isolator opened while its breaker is still ON (on load); the work
// started on a live section — above all with only one side opened on a ring
// that is closed today (backfeed). Slips: the wrong feeder's breaker, the DO
// fuse for the line, a tester that finds the backfeed, the earth before
// proving dead, the work without a test / without earth / with the NO point
// untagged / with an isolation point on the map still closed (only a breaker
// open, or the ring's tie left closed today), and listening to the coworker
// ("এলাকা আমার মুখস্থ, ম্যাপ লাগবে না" — playbook row 8; the act he pushes,
// work on the backfed section, stays deadly when the player then does it).
// Opening the other feeder's breaker on an open ring is not needed: it costs
// the docket's thorough bonus and the play's quick (third) star, with no word
// from the guide.
// Three slips strike the level out.
//
// Kit (2026-11-11): no scene control works in a praise window (`tableBusy`);
// the tie and কাজ শুরু wait for the coworker on his docket (`holdForCoworker`),
// so a fast play still meets him; the tool row is dealt in a fresh order each
// docket; gesture hints sweep over the map's switches and the tools.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_sld_isolate_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next docket by itself; the careless coworker once a play, on the
// ring that is closed today. Voice: the guide by device TTS; the coworker's
// push is silent with its caption held until recorded (his exit line is his
// recorded clip).

// ============================================================================
// Content
// ============================================================================

/// What the reason question asks about.
enum M3SldIsolateWhy { order, test, tag, both }

@immutable
class M3SldIsolateDocket {
  const M3SldIsolateDocket({
    required this.id,
    required this.kind,
    required this.why,
    required this.flip,
    required this.workLeft,
    required this.feederA,
    required this.feederX,
    required this.feederB,
    required this.firstPole,
  });
  final String id;
  final M3SldIsolateKind kind;
  final M3SldIsolateWhy why;

  /// The map mirrored; the docket feeder the left one at substation A.
  final bool flip;
  final bool workLeft;

  /// The docket's feeder, its neighbour at the same substation, the ring's other feeder.
  final String feederA;
  final String feederX;
  final String feederB;
  final int firstPole;

  String get docketBn => '$feederA ফিডার · পোল P$firstPole–P${firstPole + 2}-এ কাজ';
}

abstract final class M3SldIsolateLines {
  static const title = 'ম্যাপ দেখে বিচ্ছিন্ন';
  static const intro = 'শাটডাউনে লাইনে কাজ! ম্যাপ দেখে সেকশনটা বিচ্ছিন্ন করুন, তবেই হাত।';
  static const rounds = ['ক', 'খ', 'গ'];

  static const feeders = ['রামপুর', 'শ্যামনগর', 'কালীতলা', 'হরিপুর', 'চাঁদপাড়া', 'নিমতলা', 'গোপালপুর', 'বেলতলা'];

  // The guide's task now (tap him: the same task, a different way).
  static const askIsolate = 'ম্যাপ দেখে সেকশনটা বিচ্ছিন্ন করুন।';
  static const askNext = 'কাজের আগে আর কী বাকি?';
  static const tasks = [askIsolate, askNext];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'SLD ম্যাপ';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থ';
  static const work = 'কাজ শুরু';
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const stampDead = 'লাইন মৃত · আর্থ';

  // The reasons: the right ones fit this docket; the wrong ones are the
  // lesson's myths and field excuses — never a true rule marked wrong.
  static const whyOrderQ = 'কেন আগে ব্রেকার, পরে আইসোলেটর খুললেন?';
  static const whyTestQ = 'ম্যাপে বন্ধ দেখেও কেন টেস্টারে দেখলেন?';
  static const whyTagQ = 'খোলা NO পয়েন্টেও কেন তালা-ট্যাগ দিলেন?';
  static const whyBothQ = 'কেন অন্য ফিডারের দিকটাও খুললেন?';
  static const orderWhy = ['আইসোলেটর অন-লোডে খোলা যায় না, তাই আগে ব্রেকার', 'ব্রেকার লোড কাটে, তারপর আইসোলেটর খোলা নিরাপদ'];
  static const testWhy = ['ম্যাপ যা-ই দেখাক, কাজের আগে টেস্টারে যাচাই চাই', 'পুরনো ম্যাপ মাঠের লাইনের সাথে না-ও মিলতে পারে'];
  static const tagWhy = ['কেউ NO পয়েন্ট বন্ধ করলেই উল্টো দিক থেকে ব্যাকফিড', 'রিং ফিডারে বিদ্যুৎ উল্টো দিক থেকেও আসতে পারে'];
  static const bothWhy = ['ম্যাপে রিং আজ বন্ধ, ওদিক থেকেও বিদ্যুৎ আসছিল', 'রিং-এ উল্টো দিক থেকে ব্যাকফিড আসে, তাই দুদিক'];
  static const myths = [
    'এলাকা মুখস্থ, ম্যাপ না দেখলেও একই কাজ হতো',
    'একটা ব্রেকার খুললেই পুরো লাইনটা মরে যায়',
    'আইসোলেটর আগে খুললে কাজ তাড়াতাড়ি শেষ হয়',
    'ম্যাপে লাইন বন্ধ দেখালে টেস্টার লাগেই না',
    'ডিও ফিউজ খুললেই পুরো সেকশনটা মরা হয়ে যায়',
    'NO পয়েন্ট তো সবসময় খোলাই থাকে, ভয় নেই',
    'এক লাইনে আঁকা মানে মাঠেও একটাই তার আছে',
    // Myth 1's own words, so "রিং" / "ব্যাকফিড" / "উল্টো" never mark the right card.
    'রিং ফিডারেও এক দিক খুললেই পুরো লাইন মরা',
    'রিং-এ উল্টো দিক থেকে ব্যাকফিড আসে না কখনো',
  ];
  static const allRight = [...orderWhy, ...testWhy, ...tagWhy, ...bothWhy];

  static List<String> whyRight(M3SldIsolateDocket d) => switch (d.why) {
        M3SldIsolateWhy.order => orderWhy,
        M3SldIsolateWhy.test => testWhy,
        M3SldIsolateWhy.tag => tagWhy,
        M3SldIsolateWhy.both => bothWhy,
      };
  static String whyQuestion(M3SldIsolateDocket d) => switch (d.why) {
        M3SldIsolateWhy.order => whyOrderQ,
        M3SldIsolateWhy.test => whyTestQ,
        M3SldIsolateWhy.tag => whyTagQ,
        M3SldIsolateWhy.both => whyBothQ,
      };

  /// The careless coworker: "I know the area, no map".
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'এলাকা আমার মুখস্থ! এই ফিডারটা বন্ধ করলেই লাইন মরা — ম্যাপ লাগবে না!',
    exitLine: coworkerExit,
    right: ['ম্যাপে রিং আছে, ওদিকটাও খুলে নেব', 'ম্যাপ দেখে সব দিক বিচ্ছিন্ন করব', 'উল্টো দিকের ব্যাকফিডও আগে কাটব'],
    // The wrong ones share the right ones' words (রিং, উল্টো, ম্যাপ,
    // বিচ্ছিন্ন, ব্যাকফিড) — no tell.
    wrong: [
      'না থাক, এক দিক বিচ্ছিন্ন করলেই যথেষ্ট',
      'ব্যাকফিড এখানে আসে না, এক দিকেই চলবে',
      'আচ্ছা, তুমি এলাকা চেনো, ম্যাপ থাক',
      'হ্যাঁ, ম্যাপ দেখা সময় নষ্ট, চলো',
      'ঠিক আছে, রিং হলেও এক ফিডারেই চলবে',
      'বেশ, মুখস্থ এলাকায় ম্যাপ লাগে না',
      'উল্টো দিকে কিছু নেই, ম্যাপ থাক',
    ],
    asks: ['ও বলছে ম্যাপ লাগবে না। কী করবেন?', 'ওর মুখস্থ, না ম্যাপ?', 'ও যা বলছে, তাতে কী করবেন?'],
  );

  static const callHeld = 'ঠিক! স্মৃতি ভুল করে, আপ-টু-ডেট ম্যাপ নয়।';
  static const allSet = 'তিনটে সেকশন — ম্যাপ দেখে সব দিক বিচ্ছিন্ন, টেস্টারে মৃত, আর্থ দিয়ে কাজ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ম্যাপ উপর থেকে নিচে পড়ুন, সব সোর্স খুঁজুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtFeeder = 'ডকেটের ফিডার ম্যাপে মিলিয়েছেন';
  static const caughtOrder = 'আগে ব্রেকার, পরে আইসোলেটর';
  static const caughtNo = 'NO পয়েন্টে তালা-ট্যাগ';
  static const caughtBackfeed = 'রিং-এর উল্টো দিকও বিচ্ছিন্ন';
  static const caughtTest = 'ম্যাপের পরও টেস্টারে যাচাই';
  static const caughtEarth = 'মৃত প্রমাণের পর আর্থ';
  static const caughtCall = 'মুখস্থের কথায় “না” বলেছেন';
}

abstract final class M3SldIsolateMistakes {
  static const _dir = 'assets/game/art/m3_sld_isolate';
  static const _load = '$_dir/ab_on_load.svg';
  static const _back = '$_dir/backfeed.svg';
  static const _feeder = '$_dir/wrong_feeder.svg';
  static const _do = '$_dir/do_fuse.svg';
  static const _test = '$_dir/test_earth.svg';
  static const _tag = '$_dir/no_tag.svg';

  static const abOnLoad = DoMistake(
    key: '3.10/m3_sld_isolate/isolator-on-load',
    textBn: 'আইসোলেটর কখনো অন-লোডে খোলা যায় না! আগে ওই দিকের সার্কিট ব্রেকার খুলুন, তারপর আইসোলেটর।',
    art: _load,
    deadly: true,
    lessonPoint: 1,
  );
  static const backfeedWork = DoMistake(
    key: '3.10/m3_sld_isolate/backfeed-work',
    textBn: 'রিং ফিডারে উল্টো দিক থেকে ব্যাকফিড! ম্যাপে সব সোর্স দেখে দুদিকই বিচ্ছিন্ন করুন — তারপর টেস্টারে যাচাই।',
    art: _back,
    deadly: true,
    lessonPoint: 2,
  );
  static const liveWork = DoMistake(
    key: '3.10/m3_sld_isolate/live-work',
    textBn: 'লাইন এখনও চালু! ম্যাপে আইসোলেশন পয়েন্টগুলো খুলে, টেস্টারে মৃত প্রমাণ করে তবেই কাজ।',
    art: _back,
    deadly: true,
    lessonPoint: 2,
  );
  static const wrongFeeder = DoMistake(
    key: '3.10/m3_sld_isolate/wrong-feeder',
    textBn: 'ভুল ফিডার! ডকেটের ফিডারের নাম ম্যাপে মিলিয়ে সেই ফিডারের ব্রেকারই খুলুন।',
    art: _feeder,
    lessonPoint: 2,
  );
  static const doFuse = DoMistake(
    key: '3.10/m3_sld_isolate/do-fuse',
    textBn: 'ডিও খুললে শুধু ট্রান্সফরমার আলাদা হয়, লাইন নয়। ম্যাপে উপরে সোর্সের দিকের ব্রেকার আর আইসোলেটর দেখুন।',
    art: _do,
    lessonPoint: 1,
  );
  static const backfeedTest = DoMistake(
    key: '3.10/m3_sld_isolate/backfeed-on-tester',
    textBn: 'টেস্টার লাইভ! এক দিক খুলেছেন, কিন্তু রিং দিয়ে উল্টো দিক থেকে ব্যাকফিড আসছে — ম্যাপে অন্য সোর্স দেখুন।',
    art: _back,
    lessonPoint: 2,
  );
  // Proving dead is the film's line (3.10 line 15); the earth is the module's
  // rule (lesson 1.6), not lesson 3.10's text: no lesson point.
  static const noTest = DoMistake(
    key: '3.10/m3_sld_isolate/no-test',
    textBn: 'ম্যাপ যা-ই দেখাক, কাজের আগে টেস্টারে লাইন মৃত প্রমাণ করুন।',
    art: _test,
  );
  static const earthUnproven = DoMistake(
    key: '3.10/m3_sld_isolate/earth-unproven',
    textBn: 'আগে টেস্টারে লাইন মৃত প্রমাণ, তারপর আর্থ।',
    art: _test,
  );
  static const noEarth = DoMistake(
    key: '3.10/m3_sld_isolate/no-earth',
    textBn: 'মৃত প্রমাণের পর আর্থ দিন — তবেই লাইনে কাজ।',
    art: _test,
  );
  static const noTag = DoMistake(
    key: '3.10/m3_sld_isolate/no-tag-on-no',
    textBn: 'NO পয়েন্টে তালা-ট্যাগ দিন — কেউ বন্ধ করলেই রিং দিয়ে উল্টো দিক থেকে ব্যাকফিড আসবে।',
    art: _tag,
    lessonPoint: 2,
  );

  /// Work asked for with a point on the map still closed: only the breaker
  /// open (no isolator), or the ring's tie left closed today (lesson point 3:
  /// mark the area and its isolation points before work).
  static const notIsolated = DoMistake(
    key: '3.10/m3_sld_isolate/not-isolated',
    textBn: 'ম্যাপের সব আইসোলেশন পয়েন্ট খোলা হয়নি! ব্রেকারের পর আইসোলেটরও খুলুন — রিং হলে উল্টো দিকের টাই সুইচও।',
    art: _back,
    lessonPoint: 2,
  );

  /// Listening to "এলাকা আমার মুখস্থ" (playbook row 8: a slip; lesson myth 1).
  static const listened = DoMistake(
    key: '3.10/m3_sld_isolate/listened-memory',
    textBn: 'মুখস্থের ভরসায় নয়! রিং ফিডারে উল্টো দিক থেকেও বিদ্যুৎ আসে — ম্যাপে সব সোর্স দেখে বিচ্ছিন্ন করুন।',
    art: _back,
    lessonPoint: 2,
  );

  static List<DoMistake> get all =>
      const [abOnLoad, backfeedWork, liveWork, wrongFeeder, doFuse, backfeedTest, noTest, earthUnproven, noEarth, noTag, notIsolated, listened];
}

@immutable
class M3SldIsolateDeal {
  const M3SldIsolateDeal({required this.dockets, required this.callAt});
  final List<M3SldIsolateDocket> dockets;

  /// The docket the careless coworker comes to (the ring closed today).
  final int callAt;
}

/// Three dockets: one radial, one ring with its NO point open, one ring whose
/// NO point is closed today (any order); maps mirrored, feeders and poles vary.
M3SldIsolateDeal m3SldIsolateDeal(math.Random rng) {
  final kinds = [...M3SldIsolateKind.values]..shuffle(rng);
  final dockets = <M3SldIsolateDocket>[
    for (final (i, k) in kinds.indexed)
      () {
        final names = [...M3SldIsolateLines.feeders]..shuffle(rng);
        return M3SldIsolateDocket(
          id: 's$i',
          kind: k,
          why: switch (k) {
            M3SldIsolateKind.radial => rng.nextBool() ? M3SldIsolateWhy.order : M3SldIsolateWhy.test,
            M3SldIsolateKind.ringNo => M3SldIsolateWhy.tag,
            M3SldIsolateKind.ringClosed => M3SldIsolateWhy.both,
          },
          flip: rng.nextBool(),
          workLeft: rng.nextBool(),
          feederA: names[0],
          feederX: names[1],
          feederB: names[2],
          firstPole: 4 + rng.nextInt(30),
        );
      }(),
  ];
  return M3SldIsolateDeal(dockets: dockets, callAt: kinds.indexOf(M3SldIsolateKind.ringClosed));
}

/// The play state (pure logic).
class M3SldIsolateRun {
  M3SldIsolateRun(this.deal);
  final M3SldIsolateDeal deal;
  int index = 0;
  int slips = 0;
  int docketSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this docket ---
  final Set<M3SldIsolatePoint> opened = {};
  var tieTagged = false;
  var proved = false;
  var earthed = false;
  var workOn = false;

  /// The other feeder's breaker opened on an open ring (not needed): the
  /// docket loses its thorough bonus.
  var needless = false;

  /// A needless cut on any docket this play: no "quick" third star and no
  /// quick bonus (audit: an over-call costs at least a star), still no word.
  var overCut = false;

  bool get done => index >= deal.dockets.length;
  bool get ended => done || deadly != null;
  M3SldIsolateDocket get docket => deal.dockets[index.clamp(0, deal.dockets.length - 1)];
  M3SldIsolateKind get kind => docket.kind;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => docketSlips == 0 && !needless;

  bool closed(M3SldIsolatePoint p) => switch (p) {
        M3SldIsolatePoint.tie => kind == M3SldIsolateKind.ringClosed && !opened.contains(p),
        _ => !opened.contains(p),
      };

  /// The docket feeder's side is open (its breaker and its isolator).
  bool get sideAOpen => opened.containsAll(const [M3SldIsolatePoint.cbA, M3SldIsolatePoint.abA]);

  /// Is the work section fed from anywhere now?
  bool get live =>
      (closed(M3SldIsolatePoint.cbA) && closed(M3SldIsolatePoint.abA)) ||
      (kind == M3SldIsolateKind.ringClosed && closed(M3SldIsolatePoint.tie) && closed(M3SldIsolatePoint.cbB));

  /// Every point on the SLD that must be opened (or secured) is.
  bool get isolated =>
      sideAOpen &&
      switch (kind) {
        M3SldIsolateKind.radial => true,
        M3SldIsolateKind.ringNo => tieTagged,
        M3SldIsolateKind.ringClosed => opened.contains(M3SldIsolatePoint.tie),
      };

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    docketSlips++;
    return m;
  }

  bool get _open => !ended && !workOn;

  /// The point is on this docket's map.
  bool onMap(M3SldIsolatePoint p) => kind != M3SldIsolateKind.radial || (p != M3SldIsolatePoint.cbB && p != M3SldIsolatePoint.tie);

  /// Taps [p] on the SLD: opens it (with its tag), or tags the open NO tie.
  /// Returns the mistake, if any.
  DoMistake? tap(M3SldIsolatePoint p) {
    if (!_open || !onMap(p)) return null;
    switch (p) {
      case M3SldIsolatePoint.cbX:
        return _slip(M3SldIsolateMistakes.wrongFeeder);
      case M3SldIsolatePoint.doFuse:
        return _slip(M3SldIsolateMistakes.doFuse);
      case M3SldIsolatePoint.cbA:
        if (opened.add(p)) _tag(M3SldIsolateLines.caughtFeeder);
        return null;
      case M3SldIsolatePoint.cbB:
        if (opened.add(p) && kind == M3SldIsolateKind.ringNo) needless = overCut = true;
        return null;
      case M3SldIsolatePoint.abA:
        if (opened.contains(p)) return null;
        if (closed(M3SldIsolatePoint.cbA)) return deadly = M3SldIsolateMistakes.abOnLoad;
        opened.add(p);
        _tag(M3SldIsolateLines.caughtOrder);
        return null;
      case M3SldIsolatePoint.tie:
        if (kind == M3SldIsolateKind.ringNo) {
          if (!tieTagged) {
            tieTagged = true;
            _tag(M3SldIsolateLines.caughtNo);
          }
          return null;
        }
        if (opened.contains(p)) return null;
        if (closed(M3SldIsolatePoint.cbB)) return deadly = M3SldIsolateMistakes.abOnLoad;
        opened.add(p);
        _tag(M3SldIsolateLines.caughtBackfeed);
        return null;
    }
  }

  /// The tester on the section: true = live. A live reading with the
  /// docket feeder's side open = the backfeed found (a slip).
  (bool, DoMistake?) test() {
    if (!_open) return (false, null);
    final l = live;
    if (!l) {
      proved = true;
      _tag(M3SldIsolateLines.caughtTest);
      return (false, null);
    }
    return (true, sideAOpen ? _slip(M3SldIsolateMistakes.backfeedTest) : null);
  }

  /// The portable earth on the section.
  DoMistake? earth() {
    if (!_open || earthed) return null;
    if (!proved || live) return _slip(M3SldIsolateMistakes.earthUnproven);
    earthed = true;
    _tag(M3SldIsolateLines.caughtEarth);
    return null;
  }

  /// "কাজ শুরু". Null and [workOn] = the work starts on a dead, earthed,
  /// fully isolated section (every point on the map open or secured).
  DoMistake? start() {
    if (!_open) return null;
    if (live) return deadly = sideAOpen ? M3SldIsolateMistakes.backfeedWork : M3SldIsolateMistakes.liveWork;
    if (!proved) return _slip(M3SldIsolateMistakes.noTest);
    if (!earthed) return _slip(M3SldIsolateMistakes.noEarth);
    if (!isolated) return _slip(kind == M3SldIsolateKind.ringNo && sideAOpen ? M3SldIsolateMistakes.noTag : M3SldIsolateMistakes.notIsolated);
    workOn = true;
    return null;
  }

  /// Listening to the coworker: a slip (the docket goes on).
  DoMistake listened() => _slip(M3SldIsolateMistakes.listened);

  void next() {
    index++;
    docketSlips = 0;
    opened.clear();
    tieTagged = false;
    proved = false;
    earthed = false;
    workOn = false;
    needless = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action, reading the map ~4000 a docket:
///   radial: map, CB, AB, tester, earth, work, stamp ~1500, reason ~8200 ≈ 21200
///   ring NO: as radial + the tag                                       ≈ 22700
///   ring closed today: as radial + CB-B + tie                          ≈ 24200
/// + the coworker once ≈ 9600                                           ≈ 77700
/// 85 % ≈ 66000 → 70 s.
const kM3SldIsolateQuickMs = 70000;

@immutable
class M3SldIsolatePack {
  const M3SldIsolatePack({required this.id, required this.titleBn, this.quickMs = kM3SldIsolateQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M3SldIsolatePack> m3SldIsolatePacks = {
  'do_3_10_a': M3SldIsolatePack(id: 'do_3_10_a', titleBn: M3SldIsolateLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3SldIsolatePage extends StatefulWidget {
  const M3SldIsolatePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3SldIsolatePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3SldIsolatePage> createState() => _M3SldIsolatePageState();
}

class _M3SldIsolatePageState extends State<M3SldIsolatePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SldRunPage(
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

class _SldRunPage extends ConsumerStatefulWidget {
  const _SldRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3SldIsolatePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SldRunPage> createState() => _SldRunPageState();
}

class _SldRunPageState extends ConsumerState<_SldRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3SldIsolateRun _run = M3SldIsolateRun(m3SldIsolateDeal(widget.rng));
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

  /// The tester's lamp, a moment after it touches the section.
  bool? _tester;
  Timer? _testerTimer;

  var _freeze = false;
  Completer<void>? _frozen;

  /// Where the flash comes (design px).
  Offset? _arcAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The tool row, dealt in a fresh order each docket (never tester → earth →
  /// work laid out for the player).
  List<_Tool> _tools = _Tool.values;
  final _toolKeys = {for (final x in _Tool.values) x: GlobalKey(debugLabel: 'sld-tool-${x.name}')};

  /// The scene's touch layer (design px → global for the hint's sweep).
  final _sceneKey = GlobalKey(debugLabel: 'sld-scene');
  M3SldIsolateGeo? _hintGeo;
  final _hints = IdleHintController();

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _testerTimer?.cancel();
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
    _startDocket();
  }

  /// The scene takes a move now: never in a praise window (`tableBusy`).
  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.workOn && !_freeze;

  /// The guide's ask, keyed only on what the player has seen (the tester
  /// read dead) — never on the hidden `isolated`, so it does not tell when
  /// the map reading is complete.
  String get _task => _run.proved ? M3SldIsolateLines.askNext : M3SldIsolateLines.askIsolate;

  void _startDocket() {
    _testerTimer?.cancel();
    final d = _run.docket;
    setState(() {
      _tester = null;
      _wake++;
      // Its own Random (from the docket) so the seeded deal is not disturbed.
      _tools = [..._Tool.values]..shuffle(math.Random(d.firstPole * 7919 + d.feederA.length * 31 + _run.index * 3 + (d.flip ? 1 : 0)));
    });
    if (_run.index == _run.deal.callAt) scheduleCoworker();
    unawaited(_sayChain([M3SldIsolateLines.askIsolate]));
  }

  M3SldIsolateGeo _geoFor(SceneMetrics m, double topInset) {
    final d = _run.docket;
    return M3SldIsolateGeo.forScene(m.height, m.inset, top: topInset, flip: d.flip, workLeft: d.workLeft);
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _useTester(Offset origin) {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.5);
    final (live, m) = _run.test();
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
    if (m != null) {
      unawaited(_mistake(m, origin));
    } else if (!live) {
      unawaited(_sayChain([_task]));
    }
  }

  void _earth(Offset origin) {
    if (!_canPlay || _run.earthed) return;
    final m = _run.earth();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    _tick('sounds/learn/tag_slap.ogg', 0.6);
  }

  void _work(Offset origin) {
    if (!_canPlay) return;
    // On his docket the work waits for the coworker (a fast play meets him).
    if (holdForCoworker()) return;
    _tick('sounds/intro/click.ogg', 0.6);
    final m = _run.start();
    setState(() => _wake++);
    if (m != null) {
      _arcAt = null;
      unawaited(_mistake(m, origin));
    } else if (_run.workOn) {
      unawaited(_docketDone());
    }
  }

  void _tapScene(Offset p, M3SldIsolateGeo geo, Offset global) {
    if (_intro || _ended || _card != null || tableBusy || _freeze || _run.workOn) return;
    M3SldIsolatePoint? hit;
    for (final x in M3SldIsolatePoint.values) {
      if (_run.onMap(x) && geo.hit(x).contains(p)) {
        hit = x;
        break;
      }
    }
    if (hit == null) {
      if (!coworkerOpen) _hints.missTap();
      return;
    }
    // While he talks, only the ring's other side answers him (opening it refuses him).
    if (coworkerOpen) {
      if (coworkerChoiceUp && (hit == M3SldIsolatePoint.cbB || hit == M3SldIsolatePoint.tie)) {
        final before = _run.opened.length + (_run.tieTagged ? 1 : 0);
        final m = _run.tap(hit);
        setState(() => _wake++);
        if (m != null) {
          _tick('sounds/intro/impact_metal.ogg', 0.6);
          _arcAt = geo.point(hit);
          unawaited(_mistake(m, global));
        } else if (_run.opened.length + (_run.tieTagged ? 1 : 0) > before) {
          // Only a tap that really opens (or tags) a point refuses him.
          _tick('sounds/intro/impact_metal.ogg', 0.6);
          unawaited(answerCoworker(true, global, direct: true));
        } else {
          _tick('sounds/intro/click.ogg', 0.3);
        }
      }
      return;
    }
    // On his docket the tie waits for the coworker (a fast play meets him).
    if (hit == M3SldIsolatePoint.tie && holdForCoworker()) return;
    final before = _run.opened.length + (_run.tieTagged ? 1 : 0);
    final m = _run.tap(hit);
    setState(() => _wake++);
    if (m != null) {
      _arcAt = geo.point(hit);
      unawaited(_mistake(m, global));
      return;
    }
    if (_run.opened.length + (_run.tieTagged ? 1 : 0) > before) {
      // No guide line here: a line on "isolated" would tell the map's answer.
      _tick(hit == M3SldIsolatePoint.tie && _run.kind == M3SldIsolateKind.ringNo ? 'sounds/learn/tag_slap.ogg' : 'sounds/intro/impact_metal.ogg', 0.6);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
  }

  Future<void> _docketDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final d = _run.docket;
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M3SldIsolateLines.whyRight(d), M3SldIsolateLines.myths, widget.rng),
      question: M3SldIsolateLines.whyQuestion(d),
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startDocket();
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
  CoworkerScript get coworkerScript => M3SldIsolateLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // Too late once the tie is open: "this feeder alone" no longer fits.
    if (_ended || _run.index != _run.deal.callAt || _run.opened.contains(M3SldIsolatePoint.tie) || _run.workOn) return null;
    if (_intro || _card != null || tableBusy || _tester != null || _freeze) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a slip (playbook row 8); the docket goes on, and work
      // on the backfed section is still deadly if the player then does it.
      await _mistake(_run.listened(), origin);
      return;
    }
    _run.caught.add(M3SldIsolateLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3SldIsolateLines.callHeld, _task], mood: GuideMood.glad));
  }

  // --- gesture hints (how to touch, never what) ------------------------------
  /// The level waits for a move on the map or the tools.
  bool get _hintWaiting =>
      !_intro && !_ended && _mark == null && !struckOut && !_freeze && _card == null && !tableBusy && !coworkerOnScreen && !_run.workOn;

  /// A sweep over every switch on the map and every tool, in screen order
  /// (top → bottom, left → right) — passes over all, presses none.
  HintSpec? _hint() {
    final geo = _hintGeo;
    final box = _sceneKey.currentContext?.findRenderObject();
    if (geo == null || box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rects = <Rect>[
      for (final x in M3SldIsolatePoint.values)
        if (_run.onMap(x)) Rect.fromPoints(box.localToGlobal(geo.hit(x).topLeft), box.localToGlobal(geo.hit(x).bottomRight)),
      for (final k in _toolKeys.values) ?HintSpec.globalRectOf(k),
    ]..sort((a, b) {
        final dy = (a.center.dy - b.center.dy).abs() < 8 ? 0 : a.center.dy.compareTo(b.center.dy);
        return dy != 0 ? dy : a.center.dx.compareTo(b.center.dx);
      });
    return rects.length < 2 ? null : HintSpec.sweep(rects);
  }

  Object get _hintKey => '${_run.index}/${_run.opened.length}/${_run.tieTagged}/${_run.proved}/${_run.earthed}/${_run.slips}';

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3SldIsolateLines.tapWhy[_nudgeN++ % M3SldIsolateLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('m3sld/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// An isolator opened on load, or hands on a live section: the scene
  /// freezes grey, the flash plays in colour; then near-miss or death.
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
    _cue('sounds/accident.ogg', volume: 0.9);
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('m3sld/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3SldIsolateLines.deadlyWord : M3SldIsolateLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same docket goes on from where it was.
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

  /// Quick and clean: inside the time, every mark kept, no needless cut.
  bool get _quickRun => _run.percent == 100 && !_run.overCut && _clock.elapsedMilliseconds < widget.pack.quickMs;

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
      if (_quickRun) {
        _quickBonus = true;
        await _levelDelta(10, centre, mood: GuideMood.celebrate);
      }
    }
    final delta = await save.commitLevelScore(_rungId, _runScore);
    if (_run.passed) await save.recordBestTime(_rungId, _clock.elapsedMilliseconds);
    final stars = starsFor(passed: _run.passed, strikes: strikes, quick: _quickRun);
    if (stars > 0) await save.recordStars(_rungId, stars);
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _mark = mark;
      _totalDelta = delta;
    });
    await _say(!_run.passed ? M3SldIsolateLines.fail : (_quickBonus ? M3SldIsolateLines.quick : M3SldIsolateLines.allSet),
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
  Widget _toolButton(_Tool x) => switch (x) {
        _Tool.tester => _ToolButton(
            key: _toolKeys[x], icon: Icons.flash_on_rounded, label: M3SldIsolateLines.tester, on: _tester != null, onTapUp: (d) => _useTester(d.globalPosition)),
        _Tool.earth => _ToolButton(
            key: _toolKeys[x], icon: Icons.vertical_align_bottom_rounded, label: M3SldIsolateLines.earth, on: _run.earthed, onTapUp: (d) => _earth(d.globalPosition)),
        _Tool.work => _ToolButton(
            key: _toolKeys[x], icon: Icons.engineering_rounded, label: M3SldIsolateLines.work, on: false, onTapUp: (d) => _work(d.globalPosition)),
      };

  LinemanMode get _mode {
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_run.workOn) return LinemanMode.cheer;
    if (_tester != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M3SldIsolateMap get _map {
    final d = _run.docket;
    return M3SldIsolateMap(
      kind: d.kind,
      opened: {..._run.opened},
      tieTagged: _run.tieTagged,
      earthed: _run.earthed,
      dead: _run.workOn,
      docketBn: d.docketBn,
      feederA: d.feederA,
      feederX: d.feederX,
      feederB: d.feederB,
      firstPole: d.firstPole,
    );
  }

  List<Widget> _scene(SceneMetrics m, double topInset) {
    final geo = _hintGeo = _geoFor(m, topInset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final arc = _arcAt ?? geo.sectionBox.center;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('map'),
                child: RepaintBoundary(child: CustomPaint(painter: M3SldIsolatePainter(geo: geo, map: _map, seed: _run.index * 7 + 2))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The tester's lamp by the section.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.testerAt.dx - 36,
          top: geo.testerAt.dy - 34,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_run.workOn && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 110,
          width: 140,
          top: geo.sectionBox.center.dy - 20,
          child: IgnorePointer(child: _StampPop(text: M3SldIsolateLines.stampDead, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3SldIsolateLines.sceneLabel,
          child: GestureDetector(key: _sceneKey, behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition)),
        ),
      ),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('arc'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M3SldIsolateArcPainter(at: arc, v: v)),
            ),
          ),
        ),
      // The next docket: a short fade from the last one.
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
    final topInset = size.width <= 0 ? 0.0 : pad.top * 360 / size.width;
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.workOn && !deckUp && !coworkerOpen && _card == null;
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
              labels: M3SldIsolateLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m, topInset),
            hint: _hint,
            hintWaiting: _hintWaiting,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [for (final x in _tools) _toolButton(x)],
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 84), onLeft: coworkerFromRight),
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
                  line: M3SldIsolateLines.intro,
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
            Text(live ? M3SldIsolateLines.testerLive : M3SldIsolateLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// The hands-on tools under the map.
enum _Tool { tester, earth, work }

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
          width: 76,
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
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
      builder: (_, v, child) => Transform.rotate(angle: -0.12, child: Transform.scale(scale: 1.6 - 0.6 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
