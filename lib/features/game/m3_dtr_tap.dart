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
import 'm3_dtr_tap_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show AwakeClock, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 3.6 "ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR)", কাজ 2 "অফ-লোড ট্যাপ"
// (pack do_3_6_b, engineType m3_dtr_tap). Three village DTRs a play, each
// with a docket of low-voltage complaints from the last house of the para.
// The trainee first measures the voltage at the consumer's meter board with
// a voltmeter. Where it really is low, he changes the off-load tap — safely.
//
// The sources, and only those:
//   • lesson 3.6 pro tip 2: an off-load tap changer adjusts the output
//     voltage for small changes in the input; the DTR is 11 kV → 415/240 V
//     (point 0); work on the tank only with its earthing sound (point 1);
//   • the film's rule 1 (script line "অফ-লোড ট্যাপ চেঞ্জার দিয়ে ভোল্টেজ ঠিক
//     রাখুন, তবে শুধুমাত্র ট্রান্সফরমার এইচ টি ও এল টি দুদিক থেকে বন্ধ করে")
//     and its animation: house voltage low → HT off (AB switch opened + DO
//     fuses dropped) → LT lever off → padlock on the AB handle + portable
//     earthing set → pin out, one notch, pin in → the house voltage right.
//     The film's meter reads ~200 V low and ~236 V right; the game uses
//     readings near those.
// From the module's safety rules (the brief and lesson 1.6, NOT lesson 3.6's
// text — flagged in REGISTER.md): the tag with the lock, proving dead with a
// tester before earthing, removing the earth before switching back on, and
// measuring again after the change.
//
// Hands on: ভোল্টমিটার (tap the house's meter board) · read it (কম / ঠিক) ·
// the AB handle (ON/OFF) · the DO fuses (drop / put back) · the LT lever ·
// তালা-ট্যাগ · টেস্টার · আর্থিং · the tap dial (pin, handle, pin).
//
// Deadly: touching the tap changer with HT live (also by listening to the
// coworker, "চালু অবস্থাতেই এক ঘর ঘুরিয়ে দাও!" — MODULE3_LADDER row 18), and
// putting the earthing set on a live HT line. Slips: a misread voltmeter
// (either way), the tap touched without a reading, HT half off (AB or DO
// only), LT on, no lock-tag, not proven dead, not earthed, earthing before
// proving dead, turning with the pin in, a second notch, switching on with
// the earth on. Three slips strike the level out.
//
// No giveaways: the house lamp burns the same plain light on every site until
// the voltmeter is read; the tool row is dealt in a fresh order each play.
// Gesture hints (how, never what): a sweep over the scene's parts and the
// tools, over the two reading buttons, over the dial's handle and pin; a tap
// on the house only while the voltmeter is in hand (its one use).
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (m3_dtr_tap_world.dart), corner guide, ◆ on the table → "কেন …?"
// → the next DTR by itself; the careless coworker once a play, on a low site,
// as the fix begins — the AB handle and the DO fuses wait for him
// (holdForCoworker), so a fast play cannot skip him. Voice: the guide by device
// TTS; the coworker's push has no recorded clip yet (silent, caption held,
// until the director records it); his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// What the voltmeter will find at the house.
enum M3DtrTapKind { low, ok }

/// The docket's complaint.
enum M3DtrTapJob { dimLamp, pump, para }

/// What the reason question asks about.
enum M3DtrTapWhy { keep, isolate, earth, retest }

/// The tool in hand.
enum M3DtrTapTool { none, meter }

/// The buttons of the tool row (dealt in a fresh order each play).
enum M3DtrTapKit { meter, lock, tester, earth }

@immutable
class M3DtrTapSite {
  const M3DtrTapSite({
    required this.id,
    required this.kind,
    required this.lowVolts,
    required this.okVolts,
    required this.startPos,
    required this.job,
    required this.why,
  });
  final String id;
  final M3DtrTapKind kind;

  /// The reading before the change (a low site).
  final int lowVolts;

  /// The reading on a right site, or after the one notch.
  final int okVolts;

  /// The tap position the dial stands at (2..4).
  final int startPos;
  final M3DtrTapJob job;
  final M3DtrTapWhy why;
}

abstract final class M3DtrTapLines {
  static const title = 'অফ-লোড ট্যাপ';
  static const intro = 'শেষ বাড়িতে ভোল্টেজ কম! আগে মাপুন, তারপর নিরাপদে ট্যাপ বদলান।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The guide's task now (tap him: the same task, a different way).
  static const askMeasure = 'বাড়িতে ভোল্টেজ কত, আগে দেখুন।';
  static const askRead = 'ভোল্টমিটার কী বলছে?';
  static const askFix = 'ট্যাপ বদলাতে হবে — নিরাপদে।';
  static const askDial = 'ট্যাপ চেঞ্জার এখন আপনার হাতে।';
  static const askNext = 'এবার কী করবেন?';
  static const tasks = [askMeasure, askRead, askFix, askDial, askNext];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (tools, the docket, the meter).
  static const sceneLabel = 'ট্রান্সফরমার';
  static const dialLabel = 'ট্যাপ চেঞ্জার';
  static const meter = 'ভোল্টমিটার';
  static const lock = 'তালা-ট্যাগ';
  static const tester = 'টেস্টার';
  static const earth = 'আর্থিং';
  static const sayLow = 'ভোল্টেজ কম';
  static const sayOk = 'ভোল্টেজ ঠিক';
  static const docket = 'ডকেট';
  static String jobBn(M3DtrTapJob j) => switch (j) {
        M3DtrTapJob.dimLamp => 'শেষ বাড়িতে আলো টিমটিম করছে',
        M3DtrTapJob.pump => 'কম ভোল্টেজে পাম্প চলছে না',
        M3DtrTapJob.para => 'পাড়া থেকে কম ভোল্টেজের অভিযোগ',
      };
  static const testerLive = 'লাইভ';
  static const testerDead = '0 V';
  static const stampOk = 'ভোল্টেজ ঠিক';

  // The reasons: the right ones fit this site and what was done; the wrong
  // ones are field excuses and myths — never a true rule marked wrong.
  static const whyKeepQ = 'কেন ট্যাপে হাত দিলেন না?';
  static const whyIsolateQ = 'কেন আগে HT আর LT দুদিক বন্ধ করলেন?';
  static const whyEarthQ = 'কেন ট্যাপের আগে আর্থিং দিলেন?';
  static const whyRetestQ = 'কেন চালুর পর আবার মাপলেন?';
  static const keepWhy = ['ভোল্টমিটারে ভোল্টেজ ঠিক এল, ট্যাপ বদলের দরকার নেই', 'মেপে দেখা গেল ভোল্টেজ ঠিক, তাই ট্যাপে হাত দিইনি'];
  static const isolateWhy = ['অফ-লোড ট্যাপ ঘোরানো চলে শুধু HT-LT দুদিক বন্ধ করে', 'চালু ট্রান্সফরমারে ট্যাপে হাত দিলে প্রাণ যেতে পারে'];
  static const earthWhy = ['আর্থিং থাকলে ভুলে চালু হলেও কারেন্ট মাটিতে চলে যায়', 'তালা-ট্যাগ, মৃত প্রমাণ, আর্থিং — তবেই ট্যাপে হাত'];
  static const retestWhy = ['এক ঘর ঘোরানোর পর ভোল্টেজ ঠিক হলো কি না দেখা চাই', 'মেপে নিশ্চিত হতে হবে বাড়িতে ভোল্টেজ এখন ঠিক কি না'];
  static const myths = [
    'অফ-লোড ট্যাপ চালু অবস্থাতেও ঘোরানো যায়, ভয় নেই',
    'শুধু LT বন্ধ করলেই ট্যাপ ঘোরানো পুরোপুরি নিরাপদ',
    'বাড়ির আলো দেখেই ভোল্টেজ বোঝা যায়, মিটার লাগে না',
    'যত বেশি ঘর ঘোরাবেন, বাড়ির ভোল্টেজ তত ভালো হবে',
    'কনজিউমার তাড়া দিচ্ছেন, তাই তাড়াতাড়ি সেরে দিলাম',
    'শাটডাউন নিলে সময় নষ্ট, চালুতেই সেরে ফেলা ভালো',
    'DO নামালেই যথেষ্ট, তালা-ট্যাগ আর আর্থিং লাগে না',
  ];
  static const allRight = [...keepWhy, ...isolateWhy, ...earthWhy, ...retestWhy];

  static List<String> whyRight(M3DtrTapSite s) => switch (s.why) {
        M3DtrTapWhy.keep => keepWhy,
        M3DtrTapWhy.isolate => isolateWhy,
        M3DtrTapWhy.earth => earthWhy,
        M3DtrTapWhy.retest => retestWhy,
      };
  static String whyQuestion(M3DtrTapSite s) => switch (s.why) {
        M3DtrTapWhy.keep => whyKeepQ,
        M3DtrTapWhy.isolate => whyIsolateQ,
        M3DtrTapWhy.earth => whyEarthQ,
        M3DtrTapWhy.retest => whyRetestQ,
      };

  /// The careless coworker: turn it live.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'চালু অবস্থাতেই এক ঘর ঘুরিয়ে দাও! শাটডাউনের ঝামেলা কে করে?',
    exitLine: coworkerExit,
    right: ['না, আগে HT-LT দুদিক বন্ধ, তবে ট্যাপ', 'না, চালু ট্রান্সফরমারে ট্যাপে হাত দেব না', 'না, বন্ধ, তালা, মৃত প্রমাণ, আর্থিং — তবে'],
    wrong: [
      'ঠিক, চালু রেখেই এক ঘর ঘুরিয়ে দিই',
      'আচ্ছা, গ্লাভস তো পরা, চালুতেই সারি',
      'শাটডাউনের ঝামেলা না করে ঘুরিয়ে দিই',
      'ঠিক আছে, এক মিনিটের কাজ, চালুতেই',
      'হ্যাঁ, সাবধানে চালু অবস্থাতেই ঘোরাই',
    ],
    asks: ['ও বলছে চালু রেখেই ট্যাপ ঘোরাতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'চালু ট্রান্সফরমারে ট্যাপে হাত দেবেন?'],
  );

  static const callHeld = 'ঠিক! চালু ট্রান্সফরমারে ট্যাপে কখনো হাত নয়।';
  static const allSet = 'বাড়ি বাড়ি ঠিক ভোল্টেজ — মেপে, দুদিক বন্ধ করে, নিরাপদে এক ঘর।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে মাপুন, তারপর দুদিক বন্ধ করে ট্যাপ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtRead = 'আগে ভোল্টমিটারে মেপেছেন';
  static const caughtOk = 'ভোল্টেজ ঠিক থাকলে ট্যাপে হাত দেননি';
  static const caughtIsolate = 'HT (AB + DO) আর LT দুদিক বন্ধ';
  static const caughtSafe = 'তালা-ট্যাগ, মৃত প্রমাণ, আর্থিং';
  static const caughtNotch = 'পিন তুলে এক ঘর, পিন বসিয়ে';
  static const caughtRetest = 'চালুর পর আবার মেপেছেন';
  static const caughtCall = 'চালু ট্রান্সফরমারে “না” বলেছেন';
}

abstract final class M3DtrTapMistakes {
  static const _dir = 'assets/game/art/m3_dtr_tap';
  static const _tapLive = '$_dir/tap_live.svg';
  static const _earthLive = '$_dir/earth_live.svg';
  static const _measure = '$_dir/measure.svg';
  static const _isolate = '$_dir/isolate.svg';
  static const _loto = '$_dir/lock_earth.svg';
  static const _notch = '$_dir/pin_notch.svg';

  static const tapLive = DoMistake(
    key: '3.6/m3_dtr_tap/tap-live',
    textBn: 'চালু ট্রান্সফরমারে ট্যাপ চেঞ্জারে হাত নয়! আগে HT (AB সুইচ + DO) আর LT দুদিক বন্ধ, তালা-ট্যাগ, মৃত প্রমাণ, আর্থিং — তবে ট্যাপ।',
    art: _tapLive,
    deadly: true,
  );
  static const earthLive = DoMistake(
    key: '3.6/m3_dtr_tap/earth-live',
    textBn: 'চালু লাইনে আর্থিং লাগানো নয়! আগে HT বন্ধ, টেস্টারে মৃত প্রমাণ — তবে আর্থিং।',
    art: _earthLive,
    deadly: true,
  );
  static const unread = DoMistake(
    key: '3.6/m3_dtr_tap/tap-unmeasured',
    textBn: 'আগে বাড়িতে ভোল্টমিটারে মেপে দেখুন ভোল্টেজ সত্যিই কম কি না — তবে ট্যাপ বদলের কথা।',
    art: _measure,
  );
  static const misread = DoMistake(
    key: '3.6/m3_dtr_tap/misread',
    textBn: 'ভোল্টমিটার ভুল পড়লেন। বাড়িতে 240 V-এর কাছাকাছি = ঠিক; অনেক কম (যেমন 200 V) = ভোল্টেজ কম।',
    art: _measure,
    lessonPoint: 0,
  );
  static const htHalf = DoMistake(
    key: '3.6/m3_dtr_tap/ht-half-off',
    textBn: 'HT পুরো বন্ধ করুন — AB সুইচ খুলুন আর DO ফিউজও নামান।',
    art: _isolate,
  );
  static const ltOn = DoMistake(
    key: '3.6/m3_dtr_tap/lt-on',
    textBn: 'শুধু HT নয়, LT দিকও বন্ধ করুন — অফ-লোড ট্যাপ বদল হয় দুদিক বন্ধ করে।',
    art: _isolate,
  );
  static const noLock = DoMistake(
    key: '3.6/m3_dtr_tap/no-lock-tag',
    textBn: 'AB সুইচ খুলে তালা আর ট্যাগ লাগান, যাতে কাজের মাঝে কেউ চালু না করে দেয়।',
    art: _loto,
  );
  static const noProve = DoMistake(
    key: '3.6/m3_dtr_tap/not-proven-dead',
    textBn: 'বন্ধ করার পর টেস্টারে দেখে নিন ট্রান্সফরমার সত্যিই মৃত — তবেই হাত।',
    art: _loto,
  );
  static const noEarth = DoMistake(
    key: '3.6/m3_dtr_tap/not-earthed',
    textBn: 'মৃত প্রমাণের পর আর্থিং লাগান — তবেই ট্রান্সফরমারে হাত।',
    art: _loto,
    lessonPoint: 1,
  );
  static const earthUnproved = DoMistake(
    key: '3.6/m3_dtr_tap/earth-before-test',
    textBn: 'আর্থিং লাগানোর আগে টেস্টারে মৃত প্রমাণ করুন।',
    art: _loto,
  );
  static const energiseEarthed = DoMistake(
    key: '3.6/m3_dtr_tap/on-with-earth',
    textBn: 'আর্থিং লাগানো অবস্থায় চালু নয় — আগে আর্থিং খুলুন, তালা খুলুন, তবে চালু।',
    art: _loto,
  );
  static const pinIn = DoMistake(
    key: '3.6/m3_dtr_tap/turn-pin-in',
    textBn: 'আগে লকিং পিন তুলুন, তারপর এক ঘর ঘোরান — শেষে পিন আবার বসান।',
    art: _notch,
  );
  static const oneNotch = DoMistake(
    key: '3.6/m3_dtr_tap/second-notch',
    textBn: 'এক ঘর-ই — পিন বসিয়ে, চালু করে আবার মেপে দেখুন।',
    art: _notch,
  );

  static List<DoMistake> get all => const [tapLive, earthLive, unread, misread, htHalf, ltOn, noLock, noProve, noEarth, earthUnproved, energiseEarthed, pinIn, oneNotch];
}

@immutable
class M3DtrTapDeal {
  const M3DtrTapDeal({required this.sites, required this.callAt, this.tools = M3DtrTapKit.values});
  final List<M3DtrTapSite> sites;

  /// The site the careless coworker comes to (a low one).
  final int callAt;

  /// The tool row, left to right (never the order of the work).
  final List<M3DtrTapKit> tools;
}

/// Three DTRs: two low, one right (any order), so turning the tap everywhere
/// cannot win; each low site asks a different reason; readings, dial and
/// docket vary; the tool row is shuffled (never meter → lock → tester → earth,
/// the order of the work).
M3DtrTapDeal m3DtrTapDeal(math.Random rng) {
  const lows = [198, 200, 202, 204];
  const oks = [234, 236, 238];
  final kinds = [M3DtrTapKind.ok, M3DtrTapKind.low, M3DtrTapKind.low]..shuffle(rng);
  final whys = [M3DtrTapWhy.isolate, M3DtrTapWhy.earth, M3DtrTapWhy.retest]..shuffle(rng);
  final jobs = [...M3DtrTapJob.values]..shuffle(rng);
  var w = 0;
  final sites = <M3DtrTapSite>[
    for (final (i, k) in kinds.indexed)
      M3DtrTapSite(
        id: 't$i',
        kind: k,
        lowVolts: lows[rng.nextInt(lows.length)],
        okVolts: oks[rng.nextInt(oks.length)],
        startPos: 2 + rng.nextInt(3),
        job: jobs[i],
        why: k == M3DtrTapKind.ok ? M3DtrTapWhy.keep : whys[w++],
      ),
  ];
  final low = [
    for (final (i, s) in sites.indexed)
      if (s.kind == M3DtrTapKind.low) i,
  ];
  final callAt = low[rng.nextInt(low.length)];
  var tools = [...M3DtrTapKit.values];
  while (_inWorkOrder(tools)) {
    tools = [...M3DtrTapKit.values]..shuffle(rng);
  }
  return M3DtrTapDeal(sites: sites, callAt: callAt, tools: tools);
}

/// The tools stand in the order the work uses them (a giveaway).
bool _inWorkOrder(List<M3DtrTapKit> t) {
  final lock = t.indexOf(M3DtrTapKit.lock);
  final tester = t.indexOf(M3DtrTapKit.tester);
  final earth = t.indexOf(M3DtrTapKit.earth);
  return lock < tester && tester < earth;
}

/// The play state (pure logic).
class M3DtrTapRun {
  M3DtrTapRun(this.deal) : pos = deal.sites.first.startPos;
  final M3DtrTapDeal deal;
  int index = 0;
  int slips = 0;
  int siteSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  // --- this site ---
  var abClosed = true;
  var doIn = true;
  var ltOn = true;
  var locked = false;
  var proved = false;
  var earthed = false;
  int pos;
  var pinOut = false;
  var notched = false;
  var dialOpen = false;
  M3DtrTapTool tool = M3DtrTapTool.none;
  var readingUp = false;
  var blank = false;
  var everRead = false;

  /// What the last reading said (true = low); null = not read yet.
  bool? readLow;

  /// The site is done (a right reading at the end).
  var over = false;

  bool get done => index >= deal.sites.length;
  bool get ended => done || deadly != null;
  M3DtrTapSite get site => deal.sites[index.clamp(0, deal.sites.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  bool get htLive => abClosed && doIn;
  bool get supplied => htLive && ltOn;

  /// The voltage at the house now.
  int get volts => !supplied ? 0 : (site.kind == M3DtrTapKind.low && !notched ? site.lowVolts : site.okVolts);
  bool get low => volts > 0 && volts < 220;

  /// The reading said low and the tap is not changed yet: the fix is on.
  bool get fixing => readLow == true && !notched;

  /// Done this site without a slip (+5 on the table).
  bool get thorough => siteSlips == 0;

  /// The house lamp: a plain light until the voltmeter has been read (never
  /// the answer before the reading), then dim / bright as read.
  M3DtrTapLamp get lamp => !supplied
      ? M3DtrTapLamp.dark
      : (readLow == null && !over)
          ? M3DtrTapLamp.lit
          : (low ? M3DtrTapLamp.dim : M3DtrTapLamp.bright);

  bool get _open => !ended && !over;
  bool get _free => _open && !readingUp && !dialOpen;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    siteSlips++;
    return m;
  }

  /// Picks up the voltmeter (or puts it down).
  void holdMeter() {
    if (!_free) return;
    tool = tool == M3DtrTapTool.meter ? M3DtrTapTool.none : M3DtrTapTool.meter;
    blank = false;
  }

  /// The voltmeter's leads on the consumer's meter board.
  void tapHouse() {
    if (!_free || tool != M3DtrTapTool.meter) return;
    if (volts == 0) {
      blank = true;
    } else {
      blank = false;
      readingUp = true;
    }
  }

  /// The leads come off after a dead reading.
  void clearBlank() => blank = false;

  /// Reads the voltmeter: [sayLow] = "ভোল্টেজ কম".
  DoMistake? answer(bool sayLow) {
    if (!_open || !readingUp) return null;
    if (sayLow != low) return _slip(M3DtrTapMistakes.misread);
    readingUp = false;
    tool = M3DtrTapTool.none;
    everRead = true;
    readLow = sayLow;
    _tag(M3DtrTapLines.caughtRead);
    if (!sayLow) {
      over = true;
      _tag(notched ? M3DtrTapLines.caughtRetest : M3DtrTapLines.caughtOk);
    }
    return null;
  }

  /// The AB handle. moved = false: it did not move (locked); m = a slip.
  (bool, DoMistake?) toggleAb() {
    if (!_free || locked) return (false, null);
    if (!abClosed && earthed) return (false, _slip(M3DtrTapMistakes.energiseEarthed));
    abClosed = !abClosed;
    if (htLive) proved = false;
    blank = false;
    return (true, null);
  }

  /// The DO fuses: dropped with the operating rod, or put back.
  (bool, DoMistake?) toggleDo() {
    if (!_free) return (false, null);
    if (!doIn && earthed) return (false, _slip(M3DtrTapMistakes.energiseEarthed));
    doIn = !doIn;
    if (htLive) proved = false;
    blank = false;
    return (true, null);
  }

  /// The LT lever.
  bool toggleLt() {
    if (!_free) return false;
    ltOn = !ltOn;
    blank = false;
    return true;
  }

  /// The lock and tag on the open AB handle (or off). False = not now.
  bool toggleLock() {
    if (!_free || abClosed) return false;
    locked = !locked;
    return true;
  }

  /// The tester at the transformer: true = live, null = not now.
  bool? test() {
    if (!_free) return null;
    if (!htLive) proved = true;
    return htLive;
  }

  /// The earthing set on (after a dead test) or off. moved = it changed.
  (bool, DoMistake?) toggleEarth() {
    if (!_free) return (false, null);
    if (earthed) {
      earthed = false;
      return (true, null);
    }
    if (htLive) return (false, deadly = M3DtrTapMistakes.earthLive);
    if (!proved) return (false, _slip(M3DtrTapMistakes.earthUnproved));
    earthed = true;
    return (true, null);
  }

  /// A hand on the tap changer: opens the dial (null) or the mistake.
  DoMistake? openDial() {
    if (!_free || notched) return null;
    tool = M3DtrTapTool.none;
    blank = false;
    if (htLive) return deadly = M3DtrTapMistakes.tapLive;
    // A right reading ends the site (no tap then), so a reading here was low.
    if (!everRead) return _slip(M3DtrTapMistakes.unread);
    if (abClosed || doIn) return _slip(M3DtrTapMistakes.htHalf);
    if (ltOn) return _slip(M3DtrTapMistakes.ltOn);
    if (!locked) return _slip(M3DtrTapMistakes.noLock);
    if (!proved) return _slip(M3DtrTapMistakes.noProve);
    if (!earthed) return _slip(M3DtrTapMistakes.noEarth);
    dialOpen = true;
    _tag(M3DtrTapLines.caughtIsolate);
    _tag(M3DtrTapLines.caughtSafe);
    return null;
  }

  /// The locking pin: out, or back in (after the notch, that closes the dial).
  void pin() {
    if (!dialOpen || ended) return;
    if (!pinOut) {
      pinOut = true;
      return;
    }
    pinOut = false;
    if (notched) {
      dialOpen = false;
      _tag(M3DtrTapLines.caughtNotch);
    }
  }

  /// The handle: one notch (pin out first).
  DoMistake? turn() {
    if (!dialOpen || ended) return null;
    if (!pinOut) return _slip(M3DtrTapMistakes.pinIn);
    if (notched) return _slip(M3DtrTapMistakes.oneNotch);
    notched = true;
    pos = math.min(5, pos + 1);
    readLow = null;
    return null;
  }

  /// Fails the play (listening to the coworker).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    siteSlips = 0;
    abClosed = true;
    doIn = true;
    ltOn = true;
    locked = false;
    proved = false;
    earthed = false;
    pos = site.startPos;
    pinOut = false;
    notched = false;
    dialOpen = false;
    tool = M3DtrTapTool.none;
    readingUp = false;
    blank = false;
    everRead = false;
    readLow = null;
    over = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s).
/// ms, ~1500 per human action:
///   right site: meter, house, read ~2000 + answer, reason ~8200   ≈ 14700
///   low site: the reading ≈ 6500; AB, DO, LT, lock, tester ~2500,
///     earth, dial, pin, handle, pin ≈ 16000; earth off, unlock, DO,
///     AB, LT ≈ 7500; meter, house, read + answer ≈ 6500; the lamp
///     ~1500, reason ~8200                                          ≈ 46200 × 2
/// + the coworker once ≈ 9600                                     ≈ 116700
/// 85 % ≈ 99000 → 100 s.
const kM3DtrTapQuickMs = 100000;

@immutable
class M3DtrTapPack {
  const M3DtrTapPack({required this.id, required this.titleBn, this.quickMs = kM3DtrTapQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M3DtrTapPack> m3DtrTapPacks = {
  'do_3_6_b': M3DtrTapPack(id: 'do_3_6_b', titleBn: M3DtrTapLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3DtrTapPage extends StatefulWidget {
  const M3DtrTapPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M3DtrTapPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3DtrTapPage> createState() => _M3DtrTapPageState();
}

class _M3DtrTapPageState extends State<M3DtrTapPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _TapRunPage(
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

class _TapRunPage extends ConsumerStatefulWidget {
  const _TapRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3DtrTapPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_TapRunPage> createState() => _TapRunPageState();
}

class _TapRunPageState extends ConsumerState<_TapRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3DtrTapRun _run = M3DtrTapRun(m3DtrTapDeal(widget.rng));
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
  /// He was scheduled for this play (once, on his site's low reading).
  var _coworkerScheduled = false;

  /// The gesture hint (how to touch, never what).
  final _hints = IdleHintController();
  final _toolKeys = {for (final k in M3DtrTapKit.values) k: GlobalKey()};
  final _sayLowKey = GlobalKey();
  final _sayOkKey = GlobalKey();
  final _dialKey = GlobalKey();
  static const _dialSize = Size(220, 220);

  /// The tester's lamp, a moment after it touches the bushings.
  bool? _tester;
  Timer? _testerTimer;
  Timer? _blankTimer;

  var _freeze = false;

  /// Where the flash comes from (design px) in the deadly moment.
  Offset _arcAt = Offset.zero;
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
    _testerTimer?.cancel();
    _blankTimer?.cancel();
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

  bool get _canPlay => !_intro && !_ended && _card == null && !tableBusy && !coworkerOpen && !_run.over && !_freeze;

  String get _task {
    if (_run.readingUp) return M3DtrTapLines.askRead;
    if (_run.dialOpen) return M3DtrTapLines.askDial;
    if (_run.fixing) return M3DtrTapLines.askFix;
    if (!_run.everRead) return M3DtrTapLines.askMeasure;
    return M3DtrTapLines.askNext;
  }

  void _startSite() {
    _testerTimer?.cancel();
    _blankTimer?.cancel();
    setState(() {
      _tester = null;
      _wake++;
    });
    unawaited(_sayChain([M3DtrTapLines.askMeasure]));
  }

  // --- hands on -----------------------------------------------------------------
  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _holdMeter() {
    if (!_canPlay || _run.readingUp || _run.dialOpen) return;
    _tick('sounds/quiz_select.wav');
    setState(() {
      _run.holdMeter();
      _wake++;
    });
  }

  void _useTester() {
    if (!_canPlay) return;
    final live = _run.test();
    if (live == null) return;
    _tick('sounds/intro/click.ogg', 0.5);
    _testerTimer?.cancel();
    setState(() {
      _tester = live;
      _wake++;
    });
    _testerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tester = null);
    });
  }

  void _toggleLock() {
    if (!_canPlay) return;
    if (_run.toggleLock()) {
      _tick('sounds/learn/tag_slap.wav', 0.5);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
    setState(() => _wake++);
  }

  void _toggleEarth(Offset global) {
    if (!_canPlay) return;
    final (moved, m) = _run.toggleEarth();
    setState(() => _wake++);
    if (m != null) {
      if (m.deadly) _arcAt = Offset(M3DtrTapGeo.htX[1], _geoNow.earthBarY);
      unawaited(_mistake(m, global));
      return;
    }
    if (moved) {
      _tick('sounds/intro/impact_metal.ogg', 0.45);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
  }

  M3DtrTapGeo _geoNow = M3DtrTapGeo.forScene(780, 0);

  /// A switch moved (or refused): the sound, and a slip if any.
  void _switched((bool, DoMistake?) r, Offset global) {
    final (moved, m) = r;
    _blankTimer?.cancel();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else if (moved) {
      _tick('sounds/intro/impact_metal.ogg', 0.6);
    } else {
      _tick('sounds/intro/click.ogg', 0.3);
    }
  }

  void _tapScene(Offset p, M3DtrTapGeo geo, Offset global) {
    if (_intro || _ended || _card != null || tableBusy || _freeze || _run.over) return;
    // While he talks, only the AB handle answers him (opening it refuses him).
    if (coworkerOpen) {
      if (coworkerChoiceUp && geo.abHit.contains(p) && _run.abClosed) {
        final (moved, _) = _run.toggleAb();
        if (moved) {
          _tick('sounds/intro/impact_metal.ogg', 0.6);
          setState(() => _wake++);
          unawaited(answerCoworker(true, global, direct: true));
        }
      }
      return;
    }
    if (_run.dialOpen || _run.readingUp) return;
    // The AB handle and the DO fuses end his moment (HT off): while he is due
    // they wait for him, so a fast play cannot skip him.
    if (geo.abHit.contains(p)) {
      if (holdForCoworker()) return;
      _switched(_run.toggleAb(), global);
      return;
    }
    if (geo.doHit.contains(p)) {
      if (holdForCoworker()) return;
      _switched(_run.toggleDo(), global);
      return;
    }
    if (geo.ltHit.contains(p)) {
      final moved = _run.toggleLt();
      _switched((moved, null), global);
      return;
    }
    if (geo.dialHit.contains(p)) {
      _tick('sounds/intro/click.ogg', 0.5);
      final m = _run.openDial();
      setState(() => _wake++);
      if (m != null) {
        if (m.deadly) _arcAt = geo.dial;
        unawaited(_mistake(m, global));
      } else if (_run.dialOpen) {
        _cue('sounds/learn/card_deal_a.wav', volume: 0.5);
        unawaited(_sayChain([M3DtrTapLines.askDial]));
      }
      return;
    }
    if (!geo.houseHit.contains(p) || _run.tool != M3DtrTapTool.meter) {
      // A tap on nothing to work (the sky, the house with empty hands).
      _hints.missTap();
      return;
    }
    _tick();
    setState(() {
      _run.tapHouse();
      _wake++;
    });
    if (_run.readingUp) {
      _cue('sounds/learn/card_deal_a.wav', volume: 0.5);
      unawaited(_sayChain([M3DtrTapLines.askRead]));
    } else if (_run.blank) {
      // No supply at the house: the meter reads 0, the leads come off.
      _blankTimer?.cancel();
      _blankTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() {
          _run.clearBlank();
          _wake++;
        });
      });
    }
  }

  void _answer(bool sayLow, Offset origin) {
    if (!_canPlay || !_run.readingUp) return;
    _hush();
    final m = _run.answer(sayLow);
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, origin));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/quiz_right.wav', volume: 0.5);
    if (_run.over) {
      unawaited(_siteDone());
      return;
    }
    if (!_coworkerScheduled && _run.index == _run.deal.callAt && _run.fixing) {
      _coworkerScheduled = true;
      scheduleCoworker();
    }
    unawaited(_sayChain([_task]));
  }

  void _dialTap(Offset local, Size size, Offset global) {
    if (!_canPlay || !_run.dialOpen) return;
    if (M3DtrTapDialPainter.pinHit(size, _run.pos).contains(local)) {
      _tick('sounds/intro/click.ogg', 0.6);
      final wasNotched = _run.notched;
      setState(() {
        _run.pin();
        _wake++;
      });
      if (wasNotched && !_run.dialOpen) {
        _cue('sounds/learn/tag_slap.wav', volume: 0.5);
        unawaited(_sayChain([M3DtrTapLines.askNext]));
      }
      return;
    }
    final c = M3DtrTapDialPainter.centreOf(size);
    if ((local - c).distance > M3DtrTapDialPainter.radiusOf(size) * 1.35) {
      _hints.missTap();
      return;
    }
    final m = _run.turn();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_mistake(m, global));
    } else {
      _tick('sounds/intro/impact_metal.ogg', 0.55);
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
      deal: () => dealChoices(M3DtrTapLines.whyRight(s), M3DtrTapLines.myths, widget.rng),
      question: M3DtrTapLines.whyQuestion(s),
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
  CoworkerScript get coworkerScript => M3DtrTapLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    // His push ("turn it live") fits only while HT is still on and the tap
    // not yet changed on his site; after that he does not come.
    if (_ended || _run.index != _run.deal.callAt || !_run.fixing || !_run.htLive || _run.over) return null;
    if (_intro || _card != null || tableBusy || _run.readingUp || _run.dialOpen || _tester != null) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: a hand on the tap changer of a live transformer.
      _arcAt = _geoNow.dial;
      _run.failDeadly(M3DtrTapMistakes.tapLive);
      await _deadly(M3DtrTapMistakes.tapLive);
      return;
    }
    _run.caught.add(M3DtrTapLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M3DtrTapLines.callHeld, M3DtrTapLines.askFix], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3DtrTapLines.tapWhy[_nudgeN++ % M3DtrTapLines.tapWhy.length]
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
    final speak = await SpokenOnce.first('dtrtap/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A hand on a live transformer: the yard freezes grey and the flash comes
  /// off the tank (or the HT drops) in colour; then near-miss or death.
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
    final speak = await SpokenOnce.first('dtrtap/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M3DtrTapLines.deadlyWord : M3DtrTapLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same transformer goes on from where it was.
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
    await _say(!_run.passed ? M3DtrTapLines.fail : (_quickBonus ? M3DtrTapLines.quick : M3DtrTapLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_run.over) return LinemanMode.cheer;
    if (_run.tool != M3DtrTapTool.none || _run.readingUp || _run.dialOpen) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M3DtrTapState get _state => M3DtrTapState(
        abClosed: _run.abClosed,
        doIn: _run.doIn,
        ltOn: _run.ltOn,
        locked: _run.locked,
        earthed: _run.earthed,
        pos: _run.pos,
        pinOut: _run.pinOut,
        lamp: _run.lamp,
      );

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M3DtrTapGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final st = _state;
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
                  key: const ValueKey('yard'),
                  child: RepaintBoundary(child: CustomPaint(painter: M3DtrTapYardPainter(geo: geo, s: st, t: t, seed: _run.index * 7 + 2))),
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
      ),
      // The tester's lamp by the HT bushings.
      if (_tester != null && !_freeze)
        Positioned(
          key: const ValueKey('tester'),
          left: geo.testerAt.dx - 30,
          top: geo.testerAt.dy - 14,
          child: IgnorePointer(child: _TesterChip(live: _tester!, quiet: quiet)),
        ),
      if (_run.over && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: 220,
          width: 136,
          top: geo.house.top - 92,
          child: IgnorePointer(child: _StampPop(text: M3DtrTapLines.stampOk, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3DtrTapLines.sceneLabel,
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
              builder: (_, v, _) => CustomPaint(painter: M3DtrTapArcPainter(at: _arcAt, v: v)),
            ),
          ),
        ),
      // The next transformer: a short fade from the last one.
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

  /// One button of the tool row.
  Widget _toolButton(M3DtrTapKit k, Size size) {
    final key = _toolKeys[k]!;
    return switch (k) {
      M3DtrTapKit.meter => _ToolButton(key: key, icon: Icons.speed_rounded, label: M3DtrTapLines.meter, on: _run.tool == M3DtrTapTool.meter, onTap: _holdMeter),
      M3DtrTapKit.lock => _ToolButton(key: key, icon: Icons.lock_rounded, label: M3DtrTapLines.lock, on: _run.locked, onTap: _toggleLock),
      M3DtrTapKit.tester => _ToolButton(key: key, icon: Icons.flash_on_rounded, label: M3DtrTapLines.tester, on: _tester != null, onTap: _useTester),
      M3DtrTapKit.earth => _ToolButton(
          key: key,
          icon: Icons.vertical_align_bottom_rounded,
          label: M3DtrTapLines.earth,
          on: _run.earthed,
          onTap: () => _toggleEarth(HintSpec.globalRectOf(key)?.center ?? Offset(size.width / 2, size.height - 80)),
        ),
    };
  }

  // --- the gesture hint (how to touch, never what) ------------------------------
  /// A scene point (design px) on the screen: the frame fills the page and
  /// covers it like [FullSceneFrame] does.
  Offset _sceneToGlobal(Offset p) {
    final box = MediaQuery.sizeOf(context);
    final w = math.max(1.0, box.width);
    final sh = (360 * box.height / w).clamp(560.0, 900.0);
    final scale = math.max(box.width / 360, box.height / sh);
    final dx = (box.width - 360 * scale) / 2;
    final dy = (box.height - sh * scale) / 2;
    return Offset(dx + p.dx * scale, dy + p.dy * scale);
  }

  Rect _sceneRectToGlobal(Rect r) => Rect.fromPoints(_sceneToGlobal(r.topLeft), _sceneToGlobal(r.bottomRight));

  /// The waiting state: a new one restarts the hint count.
  String get _hintKey => '${_run.index}:${_run.readingUp}:${_run.dialOpen}:${_run.tool.name}:${_run.everRead}:${_run.notched}';

  HintSpec? _hintNow() {
    // The reading: two answers — pass over both, press none.
    if (_run.readingUp) return HintSpec.sweepOver([_sayLowKey, _sayOkKey]);
    // The dial close-up: its handle and its pin are both live — pass over both.
    if (_run.dialOpen) {
      final r = HintSpec.globalRectOf(_dialKey);
      if (r == null) return null;
      final c = r.topLeft + M3DtrTapDialPainter.centreOf(_dialSize);
      final rad = M3DtrTapDialPainter.radiusOf(_dialSize);
      return HintSpec.sweep([Rect.fromCircle(center: c, radius: rad * 0.5), M3DtrTapDialPainter.pinHit(_dialSize, _run.pos).shift(r.topLeft)]);
    }
    final geo = _geoNow;
    // The voltmeter in hand has one use: its leads on the house's meter board.
    if (_run.tool == M3DtrTapTool.meter) return HintSpec.tap(_sceneToGlobal(geo.meterBoard.center));
    // Otherwise every part that works, top to bottom, then the tool row as
    // dealt — the same pass whatever the next step is.
    return HintSpec.sweep([
      for (final r in [geo.doHit, geo.dialHit, geo.ltBox, geo.abHit, geo.house]) _sceneRectToGlobal(r),
      for (final k in _run.deal.tools) ?HintSpec.globalRectOf(_toolKeys[k]!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.over && !deckUp && !coworkerOpen && _card == null && !tableBusy;
    final s = _run.site;
    final meterUp = playing && _card == null && (_run.readingUp || _run.blank);
    const dialSize = _dialSize;
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
              labels: M3DtrTapLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hintNow,
            hintWaiting: handsOn && !_ended && !_run.blank && !coworkerOnScreen,
            hintKey: _hintKey,
            hintController: _hints,
            overlays: [
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  right: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(job: s.job)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (meterUp)
                Positioned(
                  key: const ValueKey('meter'),
                  right: 14,
                  top: pad.top + 160,
                  width: 140,
                  height: 170,
                  child: IgnorePointer(child: _MeterCard(volts: _run.blank ? 0 : _run.volts, quiet: quiet)),
                ),
              if (playing && _card == null && _run.dialOpen && !deckUp)
                Positioned(
                  key: const ValueKey('dial'),
                  left: (size.width - dialSize.width) / 2,
                  top: pad.top + 150,
                  width: dialSize.width,
                  height: dialSize.height,
                  child: Semantics(
                    key: _dialKey,
                    label: M3DtrTapLines.dialLabel,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _dialTap(d.localPosition, dialSize, d.globalPosition),
                      child: _DialCard(pos: _run.pos, pinOut: _run.pinOut, quiet: quiet),
                    ),
                  ),
                ),
              if (handsOn && _run.readingUp)
                Positioned(
                  key: const ValueKey('hud-read'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(child: KeyedSubtree(key: _sayLowKey, child: DoBigButton(label: M3DtrTapLines.sayLow, filled: true, onTapUp: (d) => _answer(true, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(child: KeyedSubtree(key: _sayOkKey, child: DoBigButton(label: M3DtrTapLines.sayOk, filled: true, onTapUp: (d) => _answer(false, d.globalPosition)))),
                    ],
                  ),
                ),
              if (handsOn && !_run.readingUp && !_run.dialOpen)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // Dealt in a fresh order each play (never the order of the work).
                    children: [for (final k in _run.deal.tools) _toolButton(k, size)],
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
                  line: M3DtrTapLines.intro,
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
                                onRead: () => unawaited(openLessonPoint(context, ref, lessonId: widget.ctx.lessonId, muted: _muted)),
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.job});
  final M3DtrTapJob job;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A7A55), width: 1.4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(M3DtrTapLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M3DtrTapLines.jobBn(job), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

/// The voltmeter in his hand, its display big enough to read.
class _MeterCard extends StatelessWidget {
  const _MeterCard({required this.volts, required this.quiet});
  final int volts;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(offset: Offset(0, 40 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: RepaintBoundary(child: CustomPaint(painter: M3DtrTapMeterPainter(volts: volts))),
      ),
    );
  }
}

/// The tap changer close up: tap the red pin, the handle, the pin.
class _DialCard extends StatelessWidget {
  const _DialCard({required this.pos, required this.pinOut, required this.quiet});
  final int pos;
  final bool pinOut;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: RepaintBoundary(child: CustomPaint(painter: M3DtrTapDialPainter(pos: pos, pinOut: pinOut))),
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
            Text(live ? M3DtrTapLines.testerLive : M3DtrTapLines.testerDead, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in use.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap});
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
        child: Text(text, textAlign: TextAlign.center, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.success)),
      ),
    );
  }
}
