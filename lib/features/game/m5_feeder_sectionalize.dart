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
import 'm5_feeder_sectionalize_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

// Lesson 5.4 "ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী ফল্ট", কাজ 1
// "একে একে ফিডার — ফল্ট কোথায়?" (pack do_5_4_a, engineType
// m5_feeder_sectionalize). Two village transformers a play, at dusk. Each one's
// HT DO fuse blows "the moment it is fitted" (the docket on the van). The
// player finds the fault by sectionalizing, with the HT DO as the meter:
//
//  • tap the LT box's door: the board shows 3 or 4 fuse carriers (road names);
//  • swipe a carrier down to pull it, drag it up to put it back;
//  • hold the dropped DO barrel 1 s: the operating rod shuts it (automatic).
//    It holds or blows — honestly, whatever the player did.
//  • LT fault: all ways out and the HT holds → ◆ "কী বোঝা গেল?"; ways back one
//    by one, the faulty one blows the HT → ◆ "কেন এই ফিডারেই?"; pull it and
//    hang the red tag on it.
//  • DTR/HT fault (2nd transformer, 40 %): it blows with every way out → ◆
//    "কী বোঝা গেল?" → send the van to patrol the HT or test the DTR with the
//    megger (either is right; lesson point 1 and pro tip 3).
//
// The lesson's rules (5.4 point 4 'সেকশনালাইজিং', point 3 permanent fault,
// myth 1 'Fault Burning … কঠোরভাবে নিষিদ্ধ', myth 2, pro tips 2–3), graded by the
// Module 5 table (docs/module_specs/module5_rulings.md M5-1 / R8, R11):
//   deadly — the DO shut with no LT way open after an instant-blast docket;
//            shut again with the blowing carrier still in (or a known faulty
//            carrier pushed into a live board); shut again after it blew with
//            every way out;
//   slip   — the DO shut with only some ways open; listening to the coworker
//            (myth 2: 'এইচটি ফিউজ উড়েছে, তার মানে সমস্যাটা এইচটি লাইনেই');
//            the red tag on the wrong way. Three slips strike the level out.
//
// Built on the shared kit (GAME_LEVEL_PLAYBOOK.md): guide first, full scene
// (m5_feeder_sectionalize_world.dart), corner guide, ◆ on the table → reason
// deck, the careless coworker once a play (on the door or the first pull; the
// next carrier / the DO waits for him — holdForCoworker), mistake cards, the
// deadly freeze (the blast in colour), the gesture hand (how, never what).
// Voice: the guide by device TTS; the coworker's push needs his recorded clip
// (listed for the director), his exit line is his existing clip.

// ============================================================================
// Content
// ============================================================================

/// The ◆ moments of a round (each asks its own reason).
enum M5FeederWhy { held, identified, ht }

/// What a move did.
enum M5FeederEvent { none, opened, pulled, restored, held, heldProof, blast, identified, htProof, tagged, pullFirst, chosen }

/// A move's outcome: the event and its mistake, if any.
@immutable
class M5FeederStep {
  const M5FeederStep(this.event, [this.mistake]);
  final M5FeederEvent event;
  final DoMistake? mistake;
  static const none = M5FeederStep(M5FeederEvent.none);
}

abstract final class M5FeederLines {
  static const title = 'একে একে ফিডার — ফল্ট কোথায়?';
  static const intro = 'গ্রামের ট্রান্সফরমারের এইচটি ফিউজ লাগাতেই বিস্ফোরণে উড়ে যাচ্ছে! ফল্টটা কোথায় — খুঁজে বের করুন।';

  // The guide's task now (tap him: the same task, a different way).
  static const askFind = 'ফল্টটা কোথায় — এইচটি, ট্রান্সফরমার, না এলটি?';
  static const askFind2 = 'আরেকটা ট্রান্সফরমার, একই উৎপাত। ফল্ট কোথায়?';
  static const askNext = 'এবার কোন ফিডারে ফল্ট — খুঁজে বের করুন।';
  static const askTag = 'দোষী ফিডারটা আলাদা করে চিহ্ন দিন।';
  static const askHt = 'এবার ফল্ট খুঁজতে কী করবেন?';
  static const tasks = [askFind, askFind2, askNext, askTag, askHt];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Short guide lines (no cost).
  static const pullFirst = 'ট্যাগের আগে ক্যারিয়ারটা খুলে নিন।';
  static const tagged = 'ঠিক! দোষী ফিডার আলাদা, লাল ট্যাগ ঝুলল।';
  static const chosen = 'ঠিক! আবার চার্জ নয় — এবার ফল্ট খুঁজে মেরামত।';
  static const callHeld = 'ঠিক! এলটি শর্টেও এইচটি ফিউজ উড়তে পারে।';

  // Labels a worker reads.
  static const sceneLabel = 'গ্রামের মোড়, ডিপি ট্রান্সফরমার';
  static const door = 'এলটি বক্স';
  static const doLabel = 'ডিও ফিউজ';
  static const tag = 'লাল ট্যাগ';
  static const patrol = 'লাইন টহল';
  static const megger = 'মেগার টেস্ট';
  static const docketHead = 'ডকেট';
  static String carrier(String road) => '$road ফিউজ';
  static const seated = 'লাগানো';
  static const pulledOut = 'খোলা';
  static String dtr(int n) => 'ডিটিআর-$n';
  static String docketLine1(M5FeederSite s) => '$docketHead · ${dtr(s.dtr)} · ${s.place}';
  static String docketLine2(M5FeederSite s) => 'এইচটি ডিও ফিউজ · আজ ${s.blownToday} বার — লাগাতেই বিস্ফোরণ';
  static String docketSpoken(M5FeederSite s) => '${dtr(s.dtr)}, ${s.place}। এইচটি ডিও ফিউজ আজ ${s.blownToday} বার, লাগাতেই বিস্ফোরণ।';

  // Dealt scene facts.
  static const roads = ['বাজার', 'স্কুল', 'হাট', 'ঘাট', 'মসজিদ', 'মন্দির', 'স্টেশন', 'কলেজ', 'পুকুর', 'মাঠ'];
  static const places = ['রামপুর মোড়', 'কালীতলা মোড়', 'হাটখোলা মোড়', 'নতুনগ্রাম মোড়', 'বটতলা মোড়', 'শিবপুর মোড়'];
  static const times = ['সন্ধ্যা 5:50', 'সন্ধ্যা 6:15', 'সন্ধ্যা 6:40', 'সন্ধ্যা 7:05'];

  // The reasons (lesson 5.4 point 4 steps 2–3, point 1; myth 1–2, pro tip 1).
  // 39–48 letters.
  static const whyQ = <M5FeederWhy, String>{
    M5FeederWhy.held: 'এইচটি ফিউজ টিকে গেল — কী বোঝা গেল?',
    M5FeederWhy.identified: 'কেন ফল্ট এই ফিডারেই?',
    M5FeederWhy.ht: 'সব এলটি খোলা, তবু উড়ল — কী বোঝা গেল?',
  };
  static const whyRight = <M5FeederWhy, List<String>>{
    M5FeederWhy.held: ['ফল্ট ট্রান্সফরমার বা এইচটিতে নয়, এলটি দিকে', 'সব এলটি খোলা রেখে টিকল — দোষ এলটি দিকেই'],
    M5FeederWhy.identified: ['এটা লাগাতেই এইচটি ফিউজ উড়ল — ফল্ট এই ফিডারে', 'বাকিগুলো লাগাতে টিকেছিল, এটাতেই উড়ে গেল'],
    M5FeederWhy.ht: ['এলটি নির্দোষ — ফল্ট ট্রান্সফরমারে বা এইচটি লাইনে', 'এলটি ছাড়াই উড়ল — দোষ ট্রান্সফরমার বা এইচটিতে'],
  };
  static const myths = [
    'কয়েকবার চার্জ করলে ফল্ট জ্বলে নিজেই সেরে যাবে',
    'মোটা তার দিয়ে ফিউজ বাঁধলে আর কখনো উড়বে না',
    'ফিউজটাই দুর্বল ছিল, নতুন ফিউজে সব ঠিক হবে',
    'বাতাসে তার ছুঁয়েছিল, এখন নিজে থেকেই ঠিক',
    'সব ফিডার একসাথে লাগিয়ে দেখলেই কাজ চলবে',
  ];

  /// Wrong reasons per question: the shared myths plus two that fit it (the
  /// HT question leaves out "it is the HT line", which is half right there).
  static const mythsFor = <M5FeederWhy, List<String>>{
    M5FeederWhy.held: [...myths, 'এইচটি ফিউজ উড়েছে মানেই দোষ এইচটি লাইনে', 'এলটি শর্টে কখনোই এইচটি ডিও ফিউজ উড়ে না'],
    M5FeederWhy.identified: [...myths, 'এইচটি ফিউজ উড়েছে মানেই দোষ এইচটি লাইনে', 'এলটি শর্টে কখনোই এইচটি ডিও ফিউজ উড়ে না'],
    M5FeederWhy.ht: [...myths, 'একবার উড়েছে তো কী, আরেকবার চার্জ করে দেখি'],
  };
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];
  static List<String> get allWhyWrong => {for (final l in mythsFor.values) ...l}.toList();

  /// The careless coworker: lesson 5.4 myth 2, and a push to walk the HT line.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ট্রান্সফরমারের এইচটি ফিউজ উড়েছে, তার মানে সমস্যাটা এইচটি লাইনেই আছে। চলো, লাইন ধরে হাঁটি!',
    exitLine: coworkerExit,
    right: [
      'না — আগে এলটি খুলে দেখি, এলটি শর্টেও এইচটি উড়ে',
      'না, বড় এলটি শর্টেও এইচটি ফিউজ উড়তে পারে',
      'না, আগে সব এলটি খুলে এইচটি লাগিয়ে দেখি',
    ],
    wrong: [
      'ঠিক বলেছ, চলো এইচটি লাইন ধরে হেঁটে দেখি',
      'হ্যাঁ, এইচটি ফিউজ মানেই এইচটি লাইনের দোষ',
      'আচ্ছা, এলটি পরে দেখব, আগে এইচটি লাইন হাঁটি',
      'ঠিক, এলটি খোলার ঝামেলা না করে লাইন হাঁটি',
      'হ্যাঁ, এইচটি লাইনেই কোথাও গাছের ডাল লেগেছে',
    ],
    asks: ['ও বলছে এইচটি লাইন ধরে হাঁটতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?', 'এইচটি ফিউজ উড়লেই কি এইচটি লাইনের দোষ?'],
  );

  static const allSet = 'দারুণ! সব এলটি খুলে, একে একে লাগিয়ে — ফল্ট ধরলেন, আবার চার্জ না করে।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে সব এলটি খুলুন, তারপর এইচটি, তারপর একে একে।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtAllOut = 'সব এলটি খুলে তবে এইচটি ফিউজ';
  static const caughtOneByOne = 'একে একে লাগিয়ে দোষী ফিডার ধরা';
  static const caughtHt = 'সব খোলা, তবু উড়ল — ট্রান্সফরমার বা এইচটি';
  static const caughtTag = 'দোষী ফিডারে লাল ট্যাগ';
  static const caughtCall = 'এইচটি লাইন ধরে হাঁটায় “না” বলেছেন';
}

abstract final class M5FeederMistakes {
  static const _dir = 'assets/game/art/m5_feeder_sectionalize';

  // Lesson points (0-based): 0 where (HT/DTR/LT), 1 transient, 2 permanent,
  // 3 sectionalizing.
  static const noOpen = DoMistake(
    key: '5.4/m5_feeder_sectionalize/no-lt-open',
    textBn: 'লাগাতেই বিস্ফোরণ মানে স্থায়ী ফল্ট — এলটি না খুলে আবার চার্জ করা মারাত্মক ভুল। আগে সমস্ত আউটগোয়িং ফিডার খুলুন।',
    art: '$_dir/no_open.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const rechargeFaulty = DoMistake(
    key: '5.4/m5_feeder_sectionalize/recharge-faulty',
    textBn: 'যে ফিডার লাগাতেই এইচটি ফিউজ উড়ল, সেটা রেখে আবার চার্জ — ফল্ট পোড়ানো কঠোরভাবে নিষিদ্ধ। ওই ফিডার খুলে আলাদা করুন।',
    art: '$_dir/recharge.svg',
    deadly: true,
    lessonPoint: 3,
  );
  static const rechargeSame = DoMistake(
    key: '5.4/m5_feeder_sectionalize/recharge-same',
    textBn: 'লাগাতেই বিস্ফোরণের পর কিছু না বদলে আবার চার্জ — ফল্ট পোড়ানো কঠোরভাবে নিষিদ্ধ। আগে সমস্ত আউটগোয়িং ফিডার খুলুন।',
    art: '$_dir/no_open.svg',
    deadly: true,
    lessonPoint: 2,
  );
  static const rechargeHt = DoMistake(
    key: '5.4/m5_feeder_sectionalize/recharge-ht',
    textBn: 'সব এলটি খোলা, তবু উড়ল — ফল্ট ট্রান্সফরমারে বা এইচটি লাইনে। আবার চার্জ নয়: লাইন টহল দিন বা মেগার দিয়ে পরীক্ষা করুন।',
    art: '$_dir/ht_case.svg',
    deadly: true,
    lessonPoint: 0,
  );
  static const partialOpen = DoMistake(
    key: '5.4/m5_feeder_sectionalize/partial-open',
    textBn: 'আগে এলটি সাইডের সমস্ত আউটগোয়িং ফিডার খুলুন, তারপর এইচটি ফিউজ — কয়েকটা খোলা থাকলে ফল্ট কোথায় বোঝা যায় না।',
    art: '$_dir/partial.svg',
    lessonPoint: 3,
  );
  static const listened = DoMistake(
    key: '5.4/m5_feeder_sectionalize/ht-myth',
    textBn: 'এইচটি ফিউজ উড়লেই এইচটি লাইনের দোষ নয় — বড় এলটি শর্টও এইচটি ফিউজ উড়িয়ে দেয়। আগে এলটি খুলে পরীক্ষা।',
    art: '$_dir/listen.svg',
    lessonPoint: 0,
  );
  static const wrongTag = DoMistake(
    key: '5.4/m5_feeder_sectionalize/wrong-tag',
    textBn: 'লাল ট্যাগ শুধু সেই ফিডারে, যেটা লাগানোর সাথে সাথে এইচটি ফিউজ উড়েছে — আগে প্রমাণ, তারপর ট্যাগ।',
    art: '$_dir/wrong_tag.svg',
    lessonPoint: 3,
  );

  static const all = [noOpen, rechargeFaulty, rechargeSame, rechargeHt, partialOpen, listened, wrongTag];
}

/// One transformer of the play.
@immutable
class M5FeederSite {
  const M5FeederSite({
    required this.dtr,
    required this.blownToday,
    required this.roads,
    required this.faulty,
    required this.phase,
    required this.place,
    required this.time,
  });

  final int dtr;
  final int blownToday;

  /// The LT ways' road names (3 or 4).
  final List<String> roads;

  /// The faulty way (an index of [roads]), or -1: the fault is in the
  /// transformer or on the HT line.
  final int faulty;

  /// The DO barrel that blows (0..2).
  final int phase;
  final String place;
  final String time;

  bool get ht => faulty < 0;
  int get ways => roads.length;

  /// 0 = early dusk … 1 = evening (from [time]).
  double get dusk => M5FeederLines.times.indexOf(time) / (M5FeederLines.times.length - 1);
}

@immutable
class M5FeederDeal {
  const M5FeederDeal({required this.sites, required this.coworkerRound, required this.coworkerOnPull});

  /// Two transformers: the first always an LT fault; the second an LT fault
  /// (60 %) or a DTR/HT fault (40 %).
  final List<M5FeederSite> sites;

  /// The coworker's round (never a DTR/HT round, where his myth is near true).
  final int coworkerRound;

  /// He comes on the first pull (true) or on the door opening (false).
  final bool coworkerOnPull;
}

M5FeederDeal m5FeederDeal(math.Random rng) {
  final roads = [...M5FeederLines.roads]..shuffle(rng);
  final places = [...M5FeederLines.places]..shuffle(rng);
  final dtrs = <int>{};
  while (dtrs.length < 2) {
    dtrs.add(3 + rng.nextInt(27));
  }
  final ht = rng.nextInt(10) < 4;
  final sites = <M5FeederSite>[];
  var r = 0;
  for (var k = 0; k < 2; k++) {
    final n = rng.nextBool() ? 3 : 4;
    sites.add(M5FeederSite(
      dtr: dtrs.elementAt(k),
      blownToday: 2 + rng.nextInt(2),
      roads: roads.sublist(r, r + n),
      faulty: k == 1 && ht ? -1 : rng.nextInt(n),
      phase: rng.nextInt(3),
      place: places[k],
      time: M5FeederLines.times[rng.nextInt(M5FeederLines.times.length)],
    ));
    r += n;
  }
  final round = sites[1].ht ? 0 : rng.nextInt(2);
  return M5FeederDeal(sites: sites, coworkerRound: round, coworkerOnPull: rng.nextBool());
}

/// The play state (pure logic).
class M5FeederRun {
  M5FeederRun(this.deal) {
    _reset();
  }
  final M5FeederDeal deal;

  int index = 0;
  int slips = 0;
  int roundSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  /// The round's work is done (the next transformer comes).
  var roundDone = false;

  // The round's state.
  var doorOpen = false;
  final Set<int> inWays = {};

  /// The HT DO fuse is shut and holding.
  var held = false;

  /// The ways in when the HT last blew (null: not yet this round).
  Set<int>? lastBlast;

  /// The HT held with every way out (the LT side is proved).
  var proof = false;

  /// The way proved faulty (it blew the HT as it went in).
  int? blower;
  int? tagged;

  /// It blew with every way out (the DTR/HT side is proved).
  var htProved = false;
  int pulls = 0;

  M5FeederSite get site => deal.sites[math.min(index, deal.sites.length - 1)];
  bool get done => index >= deal.sites.length;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => roundSlips == 0;
  bool get _open => !ended && !roundDone;

  void _reset() {
    roundSlips = 0;
    roundDone = false;
    doorOpen = false;
    inWays
      ..clear()
      ..addAll(List.generate(site.ways, (i) => i));
    held = false;
    lastBlast = null;
    proof = false;
    blower = null;
    tagged = null;
    htProved = false;
    pulls = 0;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    roundSlips++;
    return m;
  }

  M5FeederStep _die(DoMistake m) {
    deadly = m;
    return M5FeederStep(M5FeederEvent.none, m);
  }

  M5FeederStep openDoor() {
    if (!_open || doorOpen) return M5FeederStep.none;
    doorOpen = true;
    return const M5FeederStep(M5FeederEvent.opened);
  }

  /// Swipe carrier [i] down (out of its base).
  M5FeederStep pull(int i) {
    if (!_open || !doorOpen || !inWays.contains(i)) return M5FeederStep.none;
    inWays.remove(i);
    pulls++;
    return const M5FeederStep(M5FeederEvent.pulled);
  }

  /// Drag carrier [i] up into its base. On a live board (the HT holding) the
  /// faulty way blows the HT at once; a way already proved faulty pushed into
  /// a live board is charging the fault again (deadly).
  M5FeederStep restore(int i) {
    if (!_open || !doorOpen || inWays.contains(i)) return M5FeederStep.none;
    if (held && i == blower) return _die(M5FeederMistakes.rechargeFaulty);
    inWays.add(i);
    if (held && !site.ht && i == site.faulty) {
      held = false;
      lastBlast = {...inWays};
      blower = i;
      if (thorough) _tag(M5FeederLines.caughtOneByOne);
      return const M5FeederStep(M5FeederEvent.identified);
    }
    return const M5FeederStep(M5FeederEvent.restored);
  }

  /// Hold the dropped DO barrel: the operating rod shuts it.
  M5FeederStep closeDo() {
    if (!_open || held) return M5FeederStep.none;
    final last = lastBlast;
    if (last != null) {
      final b = blower;
      if (b != null && inWays.contains(b)) return _die(M5FeederMistakes.rechargeFaulty);
      // Nothing pulled since it blew: no feeder is proved here, so the card
      // blames the re-charge itself (or the DTR/HT side once that is proved).
      if (inWays.containsAll(last)) return _die(htProved ? M5FeederMistakes.rechargeHt : M5FeederMistakes.rechargeSame);
    } else if (inWays.length == site.ways) {
      return _die(M5FeederMistakes.noOpen);
    }
    final slip = inWays.isNotEmpty && !proof && blower == null ? _slip(M5FeederMistakes.partialOpen) : null;
    final faultIn = site.ht || inWays.contains(site.faulty);
    if (faultIn) {
      lastBlast = {...inWays};
      if (inWays.isEmpty) {
        htProved = true;
        if (thorough) _tag(M5FeederLines.caughtHt);
        return const M5FeederStep(M5FeederEvent.htProof);
      }
      return M5FeederStep(M5FeederEvent.blast, slip);
    }
    held = true;
    if (inWays.isEmpty && !proof) {
      proof = true;
      if (thorough) _tag(M5FeederLines.caughtAllOut);
      return const M5FeederStep(M5FeederEvent.heldProof);
    }
    return M5FeederStep(M5FeederEvent.held, slip);
  }

  /// Hang the red tag on carrier [i].
  M5FeederStep tag(int i) {
    if (!_open || !doorOpen) return M5FeederStep.none;
    final b = blower;
    // No feeder proved yet (or the DTR/HT side proved): a tag on any carrier
    // is a wrong flag. The same reply for every carrier, so it never singles
    // out the faulty way.
    if (b == null) return M5FeederStep(M5FeederEvent.none, _slip(M5FeederMistakes.wrongTag));
    if (i != b) return M5FeederStep(M5FeederEvent.none, _slip(M5FeederMistakes.wrongTag));
    if (inWays.contains(i)) return const M5FeederStep(M5FeederEvent.pullFirst);
    tagged = i;
    roundDone = true;
    if (thorough) _tag(M5FeederLines.caughtTag);
    return const M5FeederStep(M5FeederEvent.tagged);
  }

  /// DTR/HT proved: patrol the HT line or megger the transformer.
  M5FeederStep choose() {
    if (!_open || !htProved) return M5FeederStep.none;
    roundDone = true;
    return const M5FeederStep(M5FeederEvent.chosen);
  }

  /// Listened to the coworker.
  DoMistake listen() => _slip(M5FeederMistakes.listened);

  void next() {
    index++;
    if (!done) _reset();
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   LT round: door, 3–4 pulls, hold (1 s + rod), reason ~8200, 2–3 restores,
///     reason ~8200, pull, tag (2 taps), round pause 1400        ≈ 35000
///   2nd round LT (60 %) ≈ 35000, DTR/HT (40 %): door, pulls, hold,
///     reason, choice ≈ 19000                                      ≈ 28600 avg
/// + the coworker once ≈ 9600                                     ≈ 73200
/// 85 % ≈ 62000 → 65 s; an LT + LT play is longer, so 75 s (owner may tune).
const m5FeederQuickMs = 75000;

@immutable
class M5FeederPack {
  const M5FeederPack({required this.id, required this.titleBn, this.quickMs = m5FeederQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M5FeederPack> m5FeederPacks = {
  'do_5_4_a': M5FeederPack(id: 'do_5_4_a', titleBn: M5FeederLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M5FeederSectionalizePage extends StatefulWidget {
  const M5FeederSectionalizePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M5FeederPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M5FeederSectionalizePage> createState() => _M5FeederSectionalizePageState();
}

class _M5FeederSectionalizePageState extends State<M5FeederSectionalizePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FeederRunPage(
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

class _FeederRunPage extends ConsumerStatefulWidget {
  const _FeederRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M5FeederPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FeederRunPage> createState() => _FeederRunPageState();
}

class _FeederRunPageState extends ConsumerState<_FeederRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M5FeederRun _run = M5FeederRun(m5FeederDeal(widget.rng));
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

  /// The operating rod shutting the DO (an automatic beat; input waits).
  var _closing = false;
  int _closeTok = 0;

  /// A blast at the DO (the HT fuse blowing): its token; [_fire] = deadly.
  int _blastTok = 0;
  var _fire = false;

  /// The red tag is in hand (the next carrier tapped gets it).
  var _tagArmed = false;

  /// The DO hold ring.
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..addStatusListener(_onRing);
  var _holding = false;

  /// A carrier's drag so far (design px).
  final Map<int, double> _drag = {};

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final _sceneKey = GlobalKey();
  final _docketKey = GlobalKey();
  final _tagKey = GlobalKey();
  final _patrolKey = GlobalKey();
  final _meggerKey = GlobalKey();
  final _hintRng = math.Random();
  int _hintN = 0;
  HintSpec? _focus;
  DateTime _focusAt = DateTime(2000);
  M5FeederGeo? _geoNow;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M5FeederSite get _site => _run.site;

  @override
  void dispose() {
    disposeCoworker();
    _ring.dispose();
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

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze && !_closing;

  String get _task {
    if (_run.htProved) return M5FeederLines.askHt;
    if (_run.blower != null) return M5FeederLines.askTag;
    if (_run.proof) return M5FeederLines.askNext;
    return _run.index == 0 ? M5FeederLines.askFind : M5FeederLines.askFind2;
  }

  bool get _coworkerHere => _run.index == _run.deal.coworkerRound && !coworkerDone;

  Future<void> _start() async {
    _clock.start();
    _startRound();
  }

  void _startRound() {
    setState(() {
      _wake++;
      _tagArmed = false;
      _drag.clear();
    });
    unawaited(_sayChain([_task]));
  }

  // --- hands on -----------------------------------------------------------------
  void _openDoor() {
    if (!_canPlay) return;
    final s = _run.openDoor();
    if (s.event != M5FeederEvent.opened) return;
    _tick('sounds/intro/impact_metal.ogg', 0.4);
    setState(() => _wake++);
    if (_coworkerHere && !_run.deal.coworkerOnPull) scheduleCoworker();
  }

  void _dragUpdate(int i, double dy) => _drag[i] = (_drag[i] ?? 0) + dy;

  void _dragEnd(int i, Offset global) {
    final dy = _drag.remove(i) ?? 0;
    if (dy.abs() < 16) {
      _confuse(i);
      return;
    }
    if (!_canPlay) return;
    // The next carrier waits for the coworker once he is due.
    if (holdForCoworker()) return;
    final M5FeederStep s;
    if (dy > 0) {
      s = _run.pull(i);
      if (s.event == M5FeederEvent.pulled) {
        _tick('sounds/intro/drop.ogg', 0.5);
        if (_coworkerHere && _run.deal.coworkerOnPull && _run.pulls == 1) scheduleCoworker();
      }
    } else {
      s = _run.restore(i);
    }
    setState(() => _wake++);
    unawaited(_outcome(s, global));
  }

  /// A plain tap on a carrier: the tag goes on it when the tag is in hand;
  /// otherwise the hand shows how a carrier moves (on that carrier only).
  void _tapCarrier(int i, Offset global) {
    if (!_canPlay) return;
    if (_tagArmed) {
      if (holdForCoworker()) return;
      final s = _run.tag(i);
      setState(() {
        _tagArmed = false;
        _wake++;
      });
      unawaited(_outcome(s, global));
      return;
    }
    _confuse(i);
  }

  void _confuse(int i) {
    final geo = _geoNow;
    if (geo != null) {
      final r = _sceneRect(geo.carrierHit(i));
      if (r != null) {
        final up = !_run.inWays.contains(i);
        _setFocus(up ? HintSpec.drag(r.center, toward: const Offset(0, -1), travel: 30) : HintSpec.swipe(r.center, toward: const Offset(0, 1), travel: 40));
      }
    }
    _hints.missTap();
  }

  void _setFocus(HintSpec? s) {
    _focus = s;
    _focusAt = DateTime.now();
  }

  void _holdStart(Offset global) {
    if (!_canPlay || _run.held) return;
    if (holdForCoworker()) return;
    _holding = true;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    unawaited(_ring.forward(from: 0));
  }

  void _holdEnd() {
    if (!_holding) return;
    if (_ring.value < 1) {
      _ring
        ..stop()
        ..value = 0;
      _holding = false;
      final geo = _geoNow;
      final r = geo == null ? null : _sceneRect(geo.doRing(_site.phase));
      if (r != null) _setFocus(HintSpec.hold(r.center));
      _hints.missTap();
    }
  }

  void _onRing(AnimationStatus s) {
    if (s != AnimationStatus.completed || !_holding) return;
    _holding = false;
    _ring.value = 0;
    unawaited(_closeDo());
  }

  Future<void> _closeDo() async {
    if (!_canPlay) return;
    final s = _run.closeDo();
    if (s.event == M5FeederEvent.none && s.mistake == null) return;
    _hush();
    HapticFeedback.mediumImpact();
    setState(() {
      _closing = true;
      _closeTok++;
      _wake++;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 250 : 700));
    if (!mounted) return;
    setState(() => _closing = false);
    final geo = _geoNow;
    final at = geo == null ? Offset.zero : (_sceneRect(geo.doRing(_site.phase))?.center ?? Offset.zero);
    await _outcome(s, at);
  }

  void _blast() {
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 0.9);
    _cue('sounds/intro/impact_metal.ogg', volume: 0.9);
    setState(() {
      _blastTok++;
      _wake++;
    });
  }

  Future<void> _outcome(M5FeederStep s, Offset origin) async {
    final m = s.mistake;
    if (m != null && m.deadly) {
      await _deadly(m);
      return;
    }
    switch (s.event) {
      case M5FeederEvent.blast:
        _blast();
      case M5FeederEvent.held:
      case M5FeederEvent.restored:
        if (_run.held) _cue('sounds/intro/confirm.ogg', volume: 0.5);
      case M5FeederEvent.heldProof:
        _cue('sounds/intro/confirm.ogg', volume: 0.6);
        _table(M5FeederWhy.held);
      case M5FeederEvent.identified:
        _blast();
        _table(M5FeederWhy.identified);
      case M5FeederEvent.htProof:
        _blast();
        _table(M5FeederWhy.ht);
      case M5FeederEvent.pullFirst:
        unawaited(_sayChain([M5FeederLines.pullFirst]));
      case M5FeederEvent.tagged:
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        unawaited(_roundDone(M5FeederLines.tagged));
      case M5FeederEvent.chosen:
        _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
        unawaited(_roundDone(M5FeederLines.chosen));
      default:
        break;
    }
    if (m != null) {
      if (s.event == M5FeederEvent.blast) await Future<void>.delayed(Duration(milliseconds: _quiet ? 200 : 700));
      if (!mounted || _ended) return;
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
    }
  }

  void _table(M5FeederWhy w) {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/quiz_right.ogg', volume: 0.6);
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final idx = _run.index;
    unawaited(askReason(
      deal: () => dealChoices(M5FeederLines.whyRight[w]!, M5FeederLines.mythsFor[w]!, widget.rng),
      question: M5FeederLines.whyQ[w]!,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  Future<void> _roundDone(String line) async {
    _hush();
    HapticFeedback.mediumImpact();
    final idx = _run.index;
    setState(() => _wake++);
    await _sayChain([line], mood: GuideMood.glad);
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 900));
    if (!mounted || _ended || _run.index != idx) return;
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startRound();
  }

  void _arm() {
    if (!_canPlay) return;
    _tick('sounds/learn/tag_slap.ogg', 0.4);
    setState(() => _tagArmed = !_tagArmed);
  }

  void _choose(Offset global) {
    if (!_canPlay) return;
    _tick('sounds/intro/click.ogg', 0.5);
    unawaited(_outcome(_run.choose(), global));
  }

  void _readDocket() {
    // Never talk over the coworker, a mistake card or the reason deck.
    if (_intro || _ended || coworkerOpen || _card != null || reasonOpen || tableBusy || _freeze || _closing) return;
    _tick();
    unawaited(_sayChain([M5FeederLines.docketSpoken(_site)]));
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
    if (_ended) return;
    setState(() => _wake++);
    unawaited(_sayChain([_task]));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M5FeederLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerRound || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze || _closing || _holding) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      await _outcome(M5FeederStep(M5FeederEvent.none, _run.listen()), origin);
      return;
    }
    if (!_run.caught.contains(M5FeederLines.caughtCall)) _run.caught.add(M5FeederLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M5FeederLines.callHeld, _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M5FeederLines.tapWhy[_nudgeN++ % M5FeederLines.tapWhy.length]
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
      _tagArmed = false;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('feeder54/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// Charging a fault: the scene freezes grey and the blast (and the fire it
  /// starts) plays in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _ring.stop();
    _holding = false;
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    _cue('sounds/intro/impact_metal.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _fire = true;
      _closing = false;
      _tagArmed = false;
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
    final speak = await SpokenOnce.first('feeder54/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M5FeederLines.deadlyWord : M5FeederLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
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
    await _say(!_run.passed ? M5FeederLines.fail : (_quickBonus ? M5FeederLines.quick : M5FeederLines.allSet),
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
    if (_closing) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M5FeederRig get _rig => M5FeederRig(
        ways: _site.ways,
        inWays: {..._run.inWays},
        held: _run.held && !_closing,
        doorOpen: _run.doorOpen,
        phase: _site.phase,
        dusk: _site.dusk,
        tagged: _run.tagged,
        soot: _run.blower,
      );

  /// A design-px rect of the scene on screen (null before layout).
  Rect? _sceneRect(Rect r) {
    final box = _sceneKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return Rect.fromPoints(box.localToGlobal(r.topLeft), box.localToGlobal(r.bottomRight));
  }

  /// The gesture hand: in turn, a sweep over every control of the moment
  /// (the docket, the LT box or the carriers, the DO, the tag …), a swipe down
  /// on a random seated carrier, a drag up on a random pulled one, and — only
  /// while some way is out and nothing has blown yet — a hold on the DO. The
  /// faulty way is never singled out. After a confused touch: that item only.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final f = _focus;
    if (f != null && DateTime.now().difference(_focusAt) < const Duration(seconds: 5)) return f;
    _focus = null;
    final ring = _run.held ? null : _sceneRect(geo.doRing(_site.phase));
    if (!_run.doorOpen) {
      final rects = [?HintSpec.globalRectOf(_docketKey), ?_sceneRect(geo.doorHit), ?ring]..sort((a, b) => a.center.dx.compareTo(b.center.dx));
      return rects.length < 2 ? null : HintSpec.sweep(rects);
    }
    final ins = [for (var i = 0; i < _site.ways; i++) if (_run.inWays.contains(i)) i];
    final outs = [for (var i = 0; i < _site.ways; i++) if (!_run.inWays.contains(i)) i];
    HintSpec? sweep() {
      final rects = [
        ?HintSpec.globalRectOf(_docketKey),
        ?ring,
        for (var i = 0; i < _site.ways; i++) ?_sceneRect(geo.carrierHit(i)),
        ?HintSpec.globalRectOf(_tagKey),
        ?HintSpec.globalRectOf(_patrolKey),
        ?HintSpec.globalRectOf(_meggerKey),
      ];
      return rects.length < 2 ? null : HintSpec.sweep(rects);
    }

    HintSpec? onCarrier(List<int> from, bool up) {
      final r = _sceneRect(geo.carrierHit(from[_hintRng.nextInt(from.length)]));
      if (r == null) return null;
      return up ? HintSpec.drag(r.center, toward: const Offset(0, -1), travel: 30) : HintSpec.swipe(r.center, toward: const Offset(0, 1), travel: 40);
    }

    final laps = <HintSpec? Function()>[
      sweep,
      if (ins.isNotEmpty) () => onCarrier(ins, false),
      if (outs.isNotEmpty) () => onCarrier(outs, true),
      if (ring != null && outs.isNotEmpty && _run.lastBlast == null) () => HintSpec.hold(ring.center),
    ];
    return laps[_hintN++ % laps.length]();
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M5FeederGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final site = _site;
    final open = _run.doorOpen;
    final live = !_intro && !_freeze;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('crossroads'),
                child: RepaintBoundary(child: CustomPaint(painter: M5FeederPainter(geo: geo, rig: _rig, seed: site.dtr * 7 + _run.index))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
              ),
              // The road names over the carriers (labels a worker reads).
              if (open)
                for (var i = 0; i < site.ways; i++)
                  Positioned.fromRect(
                    key: ValueKey('road-${_run.index}-$i'),
                    rect: geo.labelRect(i),
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: Center(
                          child: Text(site.roads[i],
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: bangla(fontSize: 9.5, fontWeight: FontWeight.w800, height: 1.1, color: SlmColors.ivory)),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      // Taps on nothing (counted for the gesture hand).
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M5FeederLines.sceneLabel,
          child: GestureDetector(
            key: _sceneKey,
            behavior: HitTestBehavior.opaque,
            onTapUp: (_) {
              _setFocus(null);
              _hints.missTap();
            },
          ),
        ),
      ),
      if (!open && live)
        Positioned.fromRect(
          key: ValueKey('door-${_run.index}'),
          rect: geo.doorHit,
          child: Semantics(
            button: true,
            label: M5FeederLines.door,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openDoor),
          ),
        ),
      if (open && live)
        for (var i = 0; i < site.ways; i++)
          Positioned.fromRect(
            key: ValueKey('carrier-${_run.index}-$i'),
            rect: geo.carrierHit(i),
            child: Semantics(
              button: true,
              label: M5FeederLines.carrier(site.roads[i]),
              value: _run.inWays.contains(i) ? M5FeederLines.seated : M5FeederLines.pulledOut,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => _drag[i] = 0,
                onVerticalDragUpdate: (d) => _dragUpdate(i, d.delta.dy),
                onVerticalDragEnd: (d) => _dragEnd(i, d.globalPosition),
                onTapUp: (d) => _tapCarrier(i, d.globalPosition),
              ),
            ),
          ),
      if (!_run.held && live && !_closing)
        Positioned.fromRect(
          key: ValueKey('do-${_run.index}'),
          rect: geo.doRing(site.phase),
          child: Semantics(
            button: true,
            label: M5FeederLines.doLabel,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _holdStart(e.position),
              onPointerUp: (_) => _holdEnd(),
              onPointerCancel: (_) => _holdEnd(),
              child: RepaintBoundary(child: CustomPaint(painter: M5FeederRingPainter(fill: _ring))),
            ),
          ),
        ),
      if (_closing)
        Positioned.fill(
          key: ValueKey('rod-$_closeTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 650),
              builder: (_, v, _) => CustomPaint(painter: M5FeederRodPainter(geo: geo, phase: site.phase, t: v)),
            ),
          ),
        ),
      if (_blastTok > 0 && !_freeze)
        Positioned.fill(
          key: ValueKey('blast-$_blastTok'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, _) => v >= 0.999 ? const SizedBox.shrink() : CustomPaint(painter: M5FeederBlastPainter(geo: geo, phase: site.phase, v: v)),
            ),
          ),
        ),
      if (_freeze && _fire)
        Positioned.fill(
          key: const ValueKey('fire'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M5FeederBlastPainter(geo: geo, phase: site.phase, v: v, fire: true)),
            ),
          ),
        ),
      // The next transformer: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('round-${_run.index}'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet || _run.index == 0 ? 0 : 0.6, end: 0),
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final tools = handsOn && _run.doorOpen;
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
              labels: [for (final s in _run.deal.sites) M5FeederLines.dtr(s.dtr)],
              done: {for (var i = 0; i < math.min(_run.index, _run.deal.sites.length); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy && !_closing && !_holding,
            hintKey: '${_run.index}/${_run.doorOpen}/${_run.held}/${_run.blower}/${_run.htProved}',
            hintController: _hints,
            overlays: [
              // Under the docket card (top left), clear of the board.
              ...tableLayers(at: Offset(size.width / 2, pad.top + 200), quiet: quiet),
              if (!_intro && _mark == null)
                Positioned(
                  key: ValueKey('hud-docket-${_run.index}'),
                  left: 10,
                  top: pad.top + 96,
                  child: _DocketCard(key: _docketKey, site: _site, onTap: _readDocket),
                ),
              if (tools)
                Positioned(
                  key: ValueKey('hud-tools-${_run.index}-${_run.htProved}'),
                  left: 4,
                  right: 4,
                  bottom: pad.bottom + 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToolButton(key: _tagKey, icon: Icons.label_rounded, label: M5FeederLines.tag, on: _tagArmed, red: true, onTap: (_) => _arm()),
                      if (_run.htProved) ...[
                        _ToolButton(key: _patrolKey, icon: Icons.local_shipping_rounded, label: M5FeederLines.patrol, on: false, onTap: _choose),
                        _ToolButton(key: _meggerKey, icon: Icons.speed_rounded, label: M5FeederLines.megger, on: false, onTap: _choose),
                      ],
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: ValueKey('why-deck-${_run.index}-${_run.proof}-${_run.blower}'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
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
                  line: M5FeederLines.intro,
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

/// The docket from the van door: facts only. Tap: the guide reads it.
class _DocketCard extends StatelessWidget {
  const _DocketCard({super.key, required this.site, required this.onTap});
  final M5FeederSite site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = bangla(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.25, color: const Color(0xFF2A2620));
    return Semantics(
      button: true,
      label: M5FeederLines.docketHead,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 214, minHeight: 48),
          padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
          decoration: BoxDecoration(
            color: const Color(0xF2FDF8EC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFC48A2E), width: 1.4),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(M5FeederLines.docketLine1(site), style: style.copyWith(fontWeight: FontWeight.w900)),
              Text(M5FeederLines.docketLine2(site), style: style),
              Text(site.time, style: style.copyWith(color: const Color(0xFF6E6A60))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit while in hand.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.on, required this.onTap, this.red = false});
  final IconData icon;
  final String label;
  final bool on;
  final bool red;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    final ring = on ? SlmColors.success : (red ? const Color(0xFFFF7A6E) : SlmColors.gold300);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(d.globalPosition),
        child: SizedBox(
          width: 84,
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
