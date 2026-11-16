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
import 'm7_waste_handover_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro;
import 'spoken_once.dart';

export 'm7_waste_handover_world.dart' show M7BoxKind, M7HandGeo, M7HandSigns, M7Kind, M7Place, M7Vehicle, M7Waste, M7WasteInfo;

// Lesson 7.8 "পরিবেশগত আইন: আমাদের দায়িত্ব", কাজ 2 "ঠিক হাতে বর্জ্য" (pack
// do_7_8_b, engineType m7_waste_handover). The section depot's yard at its
// gate (side view): a trolley with the week's waste as plain pictures (no
// label, no colour code), a padded lamp box, a red and a green bin; vehicles
// pull in one at a time with only the signboard a worker reads:
//
//  Before the first vehicle: the loose lamps (tube light, CFL, a vapour lamp)
//    are lifted — hold, then drag — into the padded lamp box (a lamp released
//    anywhere but the box or the trolley falls and cracks = slip); the oily
//    rags / pads go in the red bin (in the green bin = slip, they come back);
//    tea cups and paper may go in the green bin (nothing scored). Each
//    finished stage has its reason.
//  Then the vehicles (4 or 5, dealt order): the অনুমোদিত রিসাইক্লিং এজেন্সি
//    (the sealed oil drum only), the কোম্পানির সংগ্রহ কেন্দ্র (the battery
//    and the circuit board), the অনুমোদিত ডিসপোজাল এজেন্সি (the lamp box),
//    the পৌরসভা garbage truck (the tea cups and paper, i.e. the green bin)
//    and, in about 2 plays of 3, a plain white van with no board. A drag
//    puts a waste on the open bed (a wrong waste for that vehicle comes
//    back = slip); the "যান" tab sends the vehicle off: right load → praise,
//    ◆, the reason; the unmarked van with nothing loaded → waved off, praise,
//    ◆, "ওই গাড়িকে কেন কিছু দিলেন না?". Anything given to the unmarked van
//    drives off with it (slip + consequence card). A legit vehicle sent off
//    while its waste still waits leaves that waste undelivered: one slip at
//    the end.
//  The coworker (X2/B1): when the municipal truck pulls in, the first drag or
//    "যান" tap waits for him. Lesson myth 2 word for word, or the shortcut
//    "everything on the garbage truck". Listening = slip, and the dealt
//    hazardous item goes onto the municipal truck (consequence card).
//
// No deadly anywhere in lesson 7.8 (owner ruling M7-6): every mistake is a
// slip, listening included. Three slips strike out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m7_waste_handover_world.dart), corner guide, a right step puts
// ◆ on the table → "কেন …?" → on; the coworker's two beats; gesture hands for
// how (a hold ring on a touched lamp, a sweep over the trolley's waste, both
// bins, the lamp box and the "যান" tab alike, a sideways nudge of a trolley
// piece) — never what.

// ============================================================================
// Content
// ============================================================================

/// Where the play stands: sorting before the vehicles, the vehicles, the end.
enum M7HandStage { prep, vehicle, done }

/// What a step's reason asks about.
enum M7HandWhy { oily, lamps, oil, elec, box, general, van }

/// The coworker's push (one per play).
enum M7HandPush { myth, shortcut }

abstract final class M7WasteHandoverLines {
  static const title = 'ঠিক হাতে বর্জ্য';
  // DRAFT wording — owner (M7-10 / M6-12): every line below.
  static const intro = 'সপ্তাহের বর্জ্য জমেছে — প্রত্যেকটা ঠিক হাতে তুলে দিন!';

  // The guide's task now (tap him: the same task, a different way).
  static const taskPrep = 'গাড়ি আসার আগে ট্রলির বর্জ্য গুছিয়ে নিন।';
  static const taskVehicle = 'গাড়ি এসেছে। বোর্ড দেখে ঠিক হাতে তুলে দিন, নয়তো ফিরিয়ে দিন।';
  static const taskArriving = 'পরের গাড়ি আসছে।';
  static const taskDone = 'সব গাড়ি বিদায় — শেষ হিসাব।';
  static String task(M7HandStage s, {bool arriving = false}) => switch (s) {
        M7HandStage.prep => taskPrep,
        M7HandStage.vehicle => arriving ? taskArriving : taskVehicle,
        M7HandStage.done => taskDone,
      };
  static const tasks = [taskPrep, taskVehicle, taskArriving, taskDone];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static const liftHow = 'ল্যাম্প ধরে একটু থামুন, তারপর তুলুন।';

  // The yard (labels a worker would read; the unmarked van has no board).
  static const sceneLabel = 'ডিপোর গেট';
  static const yanTab = 'যান';
  static const vanLabel = 'গাড়ি';
  static const trolleyLabel = 'ট্রলি';
  static const lampBoxLabel = 'ল্যাম্পের বাক্স';
  static const redBinLabel = 'লাল বিন';
  static const greenBinLabel = 'সবুজ বিন';
  static String waste(M7Waste w) => switch (w) {
        M7Waste.oilDrum => 'তেলের ড্রাম',
        M7Waste.battery => 'ব্যাটারি',
        M7Waste.board => 'সার্কিট বোর্ড',
        M7Waste.tube => 'টিউব লাইট',
        M7Waste.cfl => 'CFL ল্যাম্প',
        M7Waste.vapour => 'ভেপার ল্যাম্প',
        M7Waste.rags => 'তেল-মাখা কাপড়',
        M7Waste.pads => 'তেল-মাখা প্যাড',
        M7Waste.cups => 'চায়ের কাপ',
        M7Waste.paper => 'কাগজ',
      };
  static String vehicleLabel(M7Vehicle v) => M7HandSigns.of(v) ?? vanLabel;

  // The reasons: the right ones fit what was done; the wrong ones are the
  // lesson's myths and field excuses.
  static const whyQ = <M7HandWhy, String>{
    M7HandWhy.oily: 'তেল-মাখা কাপড় কেন আলাদা বিনে?',
    M7HandWhy.lamps: 'ল্যাম্প কেন বাক্সে সাবধানে?',
    M7HandWhy.oil: 'পুরনো তেল কেন এই গাড়িতে দিলেন?',
    M7HandWhy.elec: 'ব্যাটারি আর বোর্ড কেন সংগ্রহ কেন্দ্রে?',
    M7HandWhy.box: 'ল্যাম্পের বাক্স কেন এই গাড়িতে?',
    M7HandWhy.general: 'সাধারণ ময়লা কেন পৌরসভার গাড়িতে?',
    M7HandWhy.van: 'ওই গাড়িকে কেন কিছু দিলেন না?',
  };
  static const whyRight = <M7HandWhy, List<String>>{
    M7HandWhy.oily: ['বিপজ্জনক বর্জ্য সাধারণ ময়লার সাথে ফেলা যায় না', 'বিপজ্জনক বর্জ্য আলাদা করে নির্দিষ্ট বিনে ফেলতে হয়'],
    M7HandWhy.lamps: ['ভাঙলে ভেতরের পারদ ছড়িয়ে ক্ষতি করে, তাই সাবধানে', 'না ভেঙে সাবধানে সংগ্রহ করতে হয়, ভেতরে পারদ আছে'],
    M7HandWhy.oil: ['এই তেল শুধু অনুমোদিত রিসাইক্লিং এজেন্সির হাতেই যাবে', 'বিপজ্জনক তেল অনুমোদিত রিসাইক্লিং এজেন্সিকেই দিতে হয়'],
    M7HandWhy.elec: ['পুরনো ব্যাটারি আর বোর্ড সংগ্রহ কেন্দ্রে জমা দিতে হয়', 'কোম্পানির সংগ্রহ কেন্দ্রেই এসব জমা দেওয়ার নিয়ম'],
    M7HandWhy.box: ['বাক্সের ল্যাম্প অনুমোদিত ডিসপোজাল এজেন্সির কাছে যায়', 'পারদভরা ল্যাম্প অনুমোদিত ডিসপোজাল এজেন্সিকেই পাঠাতে হয়'],
    M7HandWhy.general: ['শুধু সাধারণ ময়লাই সাধারণ ময়লার গাড়িতে যেতে পারে', 'বিপজ্জনক বর্জ্য ছাড়া শুধু সাধারণ ময়লাই এই গাড়ির কাজ'],
    M7HandWhy.van: ['বোর্ড নেই, তাই অনুমোদিত হাত কি না জানার উপায় নেই', 'অনুমোদিত নয় এমন গাড়িকে বিপজ্জনক বর্জ্য দেওয়া যায় না'],
  };
  static const myths = [
    'আমাদের মতো ছোট দলের বর্জ্যে আইনের কিছু যায় আসে না',
    'বাক্সে রাখা বা না রাখা একই কথা, ভেঙে গেলেও চলে',
    'ময়লা তো ময়লাই, যেকোনো গাড়ি এলেই তুলে দিলে হয়',
    'যে গাড়ি আগে আসে, তাকেই সব বর্জ্য দিয়ে দিলেই হয়',
    'পুরনো ব্যাটারি মাটিতে ফেললে মাটি সবটাই শুষে নেয়',
    'জরিমানা শুধু বড় বড় ফ্যাক্টরির হয়, আমাদের নয়',
    'বোর্ড না থাকলেও গাড়ি নিয়ে গেলেই বর্জ্যের কাজ শেষ',
  ];
  static List<String> get allWhyRight => [for (final l in whyRight.values) ...l];

  // The careless coworker (one push a play, at the municipal truck's arrival).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  // Lesson 7.8 myth 2, word for word (M7-10).
  static const coworkerMyth = CoworkerScript(
    line: 'পরিবেশের আইন তো শুধু বড় বড় ফ্যাক্টরির জন্য, আমাদের এসব মানার দরকার নেই।',
    exitLine: coworkerExit,
    right: ['না, আইন সবার জন্য, ব্যক্তিগতভাবেও বড় জরিমানা হয়', 'না, ছোট দলকেও আইন মানতে হয়, জরিমানা বড় হয়', 'না, বিপজ্জনক বর্জ্যের আইন সবার জন্য, আমাদেরও'],
    wrong: [
      'ঠিক, আমাদের মতো ছোট দলে আইন তেমন খাটে না',
      'ঠিক, জরিমানা তো শুধু বড় কোম্পানিরই হয়',
      'ঠিক, ব্যাটারি একটা গেলে তেমন কিছু হয় না',
      'আচ্ছা, ও আইন তো ফ্যাক্টরির জন্য, আমাদের নয়',
      'হ্যাঁ, আমাদের এসব মানার তেমন দরকার নেই',
    ],
    asks: ['কী করবেন?', 'ও বলছে আইন আমাদের জন্য নয়। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  // The 7.8b shortcut line (M7-10).
  static const coworkerShortcut = CoworkerScript(
    line: 'অত ঝামেলা কেন? সব এই ময়লার গাড়িতেই তুলে দাও।',
    exitLine: coworkerExit,
    right: ['না, প্রত্যেক বর্জ্য শুধু তার অনুমোদিত হাতে যাবে', 'না, বিপজ্জনক বর্জ্য ময়লার গাড়িতে দেওয়া যায় না', 'না, সব এক গাড়িতে নয়, ঠিক হাতেই তুলে দেব'],
    wrong: [
      'ঠিক, ময়লার গাড়িই সব নিয়ে যাক, আমাদের কী দায়',
      'ঠিক, এতগুলো গাড়ির অপেক্ষা কে করে বসে বসে',
      'আচ্ছা, সব এক গাড়িতেই তুলে দিই, কাজ মিটুক',
      'হ্যাঁ, ঝামেলা কমুক, সব ওই ময়লার গাড়িতেই দিই',
      'ঠিক আছে, ময়লা তো ময়লাই, সব তুলে দিই ওতে',
    ],
    asks: ['কী করবেন?', 'ও বলছে সব ময়লার গাড়িতে দিতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M7HandPush p) => switch (p) {
        M7HandPush.myth => coworkerMyth,
        M7HandPush.shortcut => coworkerShortcut,
      };
  static const allCoworkers = [coworkerMyth, coworkerShortcut];

  static String callHeld(M7HandPush p) => switch (p) {
        M7HandPush.myth => 'ঠিক! আইন সবার জন্য, জরিমানাও বড়।',
        M7HandPush.shortcut => 'ঠিক! প্রত্যেক বর্জ্য শুধু তার অনুমোদিত হাতে।',
      };

  static const allSet = 'সব বর্জ্য ঠিক হাতে — পরিবেশ বাঁচল!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে গুছিয়ে নিন, তারপর ঠিক হাতে তুলে দিন।';

  // "আজ যা ধরলেন".
  static const caughtLamps = 'ল্যাম্প না ভেঙে বাক্সে';
  static const caughtOily = 'তেল-মাখা কাপড় আলাদা বিনে';
  static const caughtOil = 'পুরনো তেল রিসাইক্লিং এজেন্সিতে';
  static const caughtElec = 'ব্যাটারি-বোর্ড সংগ্রহ কেন্দ্রে';
  static const caughtBox = 'ল্যাম্পের বাক্স ডিসপোজাল এজেন্সিতে';
  static const caughtGeneral = 'সাধারণ ময়লা পৌরসভার গাড়িতে';
  static const caughtVan = 'বোর্ড ছাড়া গাড়ি ফিরিয়েছেন';
  static const caughtNo = 'ওর কথায় “না” বলেছেন';

  /// The coworker's new lines (to record in his voice; tool/rival_clip.py).
  static List<String> get newRivalLines => [for (final c in allCoworkers) c.line];

  /// The guide's new spoken lines (to record; until then the device voice).
  static List<String> get newGuideLines => [
        intro,
        ...tasks,
        liftHow,
        ...whyQ.values,
        for (final c in allCoworkers) ...c.asks.where((a) => !_oldAsks.contains(a)),
        for (final p in M7HandPush.values) callHeld(p),
        allSet,
        fail,
        for (final m in M7WasteHandoverMistakes.all) m.textBn,
      ];
  static const _oldAsks = {'কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'};
}

abstract final class M7WasteHandoverMistakes {
  static const _dir = 'assets/game/art/m7_waste_handover';

  // DRAFT wording — owner (M7-10 / M6-12). Lesson 7.8 points: oil 0, battery
  // and e-waste 1, lamps 2; pro tip 2 has no point (null). All slips (M7-6).
  static const oilyGreen = DoMistake(
    key: '7.8/m7_waste_handover/oily-green',
    textBn: 'তেল-মাখা কাপড় সাধারণ ময়লার বিনে! এটা বিপজ্জনক বর্জ্য — আলাদা করে নির্দিষ্ট ডাস্টবিনে ফেলতে হয়।',
    art: '$_dir/oily_green.svg',
  );
  static const hazGreen = DoMistake(
    key: '7.8/m7_waste_handover/haz-green',
    textBn: 'বিপজ্জনক বর্জ্য সাধারণ ময়লার সাথে ফেলা যায় না। সাধারণ বিনে নয় — তার অনুমোদিত হাতেই যাবে।',
    art: '$_dir/haz_green.svg',
    lessonPoint: 1,
  );
  static const hazMunicipal = DoMistake(
    key: '7.8/m7_waste_handover/haz-municipal',
    textBn: 'ময়লার গাড়িতে বিপজ্জনক বর্জ্য নেওয়া চলে না! সাধারণ ময়লার সাথে ফেলা যাবে না — আইনে মানা।',
    art: '$_dir/haz_municipal.svg',
    lessonPoint: 1,
  );
  static const wrongOil = DoMistake(
    key: '7.8/m7_waste_handover/wrong-oil',
    textBn: 'পুরনো তেল শুধুমাত্র অনুমোদিত রিসাইক্লিং এজেন্সির হাতে দিতে হয়। এই গাড়ির কাছে নয়।',
    art: '$_dir/wrong_oil.svg',
    lessonPoint: 0,
  );
  static const wrongElec = DoMistake(
    key: '7.8/m7_waste_handover/wrong-elec',
    textBn: 'পুরনো ব্যাটারি আর খারাপ সার্কিট বোর্ড কোম্পানির নির্ধারিত সংগ্রহ কেন্দ্রে জমা দিতে হয়।',
    art: '$_dir/wrong_elec.svg',
    lessonPoint: 1,
  );
  static const wrongLamp = DoMistake(
    key: '7.8/m7_waste_handover/wrong-lamp',
    textBn: 'পারদভরা ল্যাম্প না ভেঙে অনুমোদিত ডিসপোজাল এজেন্সির কাছে পাঠাতে হয়। এই গাড়িটা সেই এজেন্সি নয়।',
    art: '$_dir/wrong_lamp.svg',
    lessonPoint: 2,
  );
  static const wrongRed = DoMistake(
    key: '7.8/m7_waste_handover/wrong-red',
    textBn: 'তেল-মাখা কাপড়ের বিন এই গাড়ির জন্য নয়। বিপজ্জনক বর্জ্য আলাদা বিনেই থাকবে।',
    art: '$_dir/wrong_red.svg',
  );
  static const wrongGeneral = DoMistake(
    key: '7.8/m7_waste_handover/wrong-general',
    textBn: 'সাধারণ ময়লা এই গাড়ির জন্য নয়। অনুমোদিত এজেন্সির কাছে শুধু তাদের বর্জ্যই যায়।',
    art: '$_dir/wrong_general.svg',
  );
  static const vanTake = DoMistake(
    key: '7.8/m7_waste_handover/van-take',
    textBn: 'বোর্ড ছাড়া গাড়ির হাতে বর্জ্য দিয়ে ফেললেন! কে নেয়, কোথায় ফেলে কেউ জানে না — মাটি আর জল দূষিত হতে পারে। শুধু অনুমোদিত হাতে দিন।',
    art: '$_dir/van_take.svg',
    lessonPoint: 0,
  );
  static const lampCrack = DoMistake(
    key: '7.8/m7_waste_handover/lamp-crack',
    textBn: 'ল্যাম্প ভেঙে গেল! ভেতরের পারদ ছড়ায়। ধরে সাবধানে বাক্সে রাখতে হয়, ছেড়ে দিতে নেই।',
    art: '$_dir/lamp_crack.svg',
    lessonPoint: 2,
  );
  static const undelivered = DoMistake(
    key: '7.8/m7_waste_handover/undelivered',
    textBn: 'ঠিক গাড়ি এসে ফিরে গেল, বর্জ্য পড়ে রইল! প্রত্যেক বর্জ্য তার অনুমোদিত হাতে তুলে দিতে হয়।',
    art: '$_dir/undelivered.svg',
  );
  static const listen = DoMistake(
    key: '7.8/m7_waste_handover/listen-dump',
    textBn: 'বিপজ্জনক বর্জ্য ময়লার গাড়িতে গেল! ডাম্পের মাটিতে ব্যাটারির বিষ চুঁইয়ে জল আর খাবারে মেশে। আইন সবার জন্য, জরিমানাও বড়।',
    art: '$_dir/listen_dump.svg',
    lessonPoint: 1,
  );

  static const List<DoMistake> all = [
    oilyGreen,
    hazGreen,
    hazMunicipal,
    wrongOil,
    wrongElec,
    wrongLamp,
    wrongRed,
    wrongGeneral,
    vanTake,
    lampCrack,
    undelivered,
    listen,
  ];
}

/// The lesson's rule for each waste: the vehicle that takes it.
M7Vehicle? m7HandReceiver(M7Kind k) => switch (k) {
      M7Kind.oil => M7Vehicle.recycler,
      M7Kind.elec => M7Vehicle.collection,
      M7Kind.lamp => M7Vehicle.disposal,
      M7Kind.general => M7Vehicle.municipal,
      M7Kind.oily => null,
    };

M7HandWhy m7HandWhyOf(M7Vehicle v) => switch (v) {
      M7Vehicle.recycler => M7HandWhy.oil,
      M7Vehicle.collection => M7HandWhy.elec,
      M7Vehicle.disposal => M7HandWhy.box,
      M7Vehicle.municipal => M7HandWhy.general,
      M7Vehicle.unmarked => M7HandWhy.van,
    };

@immutable
class M7HandDeal {
  const M7HandDeal({required this.items, required this.slotOf, required this.order, required this.push});

  /// What lies on the trolley, in dealt order.
  final List<M7Waste> items;

  /// The trolley cell of each piece.
  final Map<M7Waste, int> slotOf;

  /// The vehicles in the order they pull in (4 authorised/municipal, and the
  /// unmarked van in about 2 plays of 3).
  final List<M7Vehicle> order;
  final M7HandPush push;

  bool get hasVan => order.contains(M7Vehicle.unmarked);
}

M7HandDeal m7HandDeal(math.Random rng) {
  final items = <M7Waste>[M7Waste.oilDrum];
  final lamps = [M7Waste.tube, M7Waste.cfl, M7Waste.vapour]..shuffle(rng);
  items.addAll(lamps.take(1 + rng.nextInt(3)));
  final e = rng.nextInt(3);
  if (e != 1) items.add(M7Waste.battery);
  if (e != 0) items.add(M7Waste.board);
  final oily = [M7Waste.rags, M7Waste.pads]..shuffle(rng);
  items.addAll(oily.take(1 + rng.nextInt(2)));
  final general = [M7Waste.cups, M7Waste.paper]..shuffle(rng);
  items.addAll(general.take(1 + rng.nextInt(2)));
  items.shuffle(rng);
  final cells = List<int>.generate(M7HandGeo.slots, (i) => i)..shuffle(rng);
  final order = [M7Vehicle.recycler, M7Vehicle.collection, M7Vehicle.disposal, M7Vehicle.municipal]..shuffle(rng);
  if (rng.nextInt(3) != 0) order.insert(rng.nextInt(order.length + 1), M7Vehicle.unmarked);
  return M7HandDeal(
    items: items,
    slotOf: {for (final (i, w) in items.indexed) w: cells[i]},
    order: order,
    push: M7HandPush.values[rng.nextInt(2)],
  );
}

/// Where a piece of waste is now.
enum M7Spot { trolley, lampBox, redBin, greenBin, loaded, lost, cracked }

enum M7PieceKind { item, lampBox, redBin, greenBin }

/// What the finger holds: one waste, or a whole container (its contents).
@immutable
class M7Piece {
  const M7Piece.item(M7Waste this.w) : kind = M7PieceKind.item;
  const M7Piece.box(this.kind) : w = null;
  final M7PieceKind kind;
  final M7Waste? w;

  @override
  bool operator ==(Object other) => other is M7Piece && other.kind == kind && other.w == w;

  @override
  int get hashCode => Object.hash(kind, w);
}

/// What a release did.
enum M7DropKind { back, placed, loaded, slip, vanLeaves }

@immutable
class M7Drop {
  const M7Drop(this.kind, {this.mistake, this.cracked = false});
  final M7DropKind kind;
  final DoMistake? mistake;
  final bool cracked;
  static const back = M7Drop(M7DropKind.back);
}

/// What the "যান" tab did: [why] is null when nothing right was handed over.
@immutable
class M7Depart {
  const M7Depart(this.why);
  final M7HandWhy? why;
}

/// The play state (pure logic).
class M7HandRun {
  M7HandRun(this.deal) : spot = {for (final w in deal.items) w: M7Spot.trolley};
  final M7HandDeal deal;
  final Map<M7Waste, M7Spot> spot;

  var stage = M7HandStage.prep;
  int vehicleIx = -1;

  /// The vehicle stands at the bay with its driver waiting (not on the way in or out).
  var here = false;
  int slips = 0;
  int stepSlips = 0;
  final List<String> caught = [];

  /// A right step is in; its reason comes next ([whyDeparture]: the vehicle's).
  M7HandWhy? why;
  var whyDeparture = false;
  var lampsAsked = false;
  var oilyAsked = false;

  /// What is loaded on the bay's vehicle, and what he dumped there.
  final List<M7Waste> bed = [];
  final List<M7Waste> dumped = [];
  final List<M7Vehicle> handed = [];
  final List<M7Vehicle> wavedEmpty = [];

  M7Vehicle? get vehicle => vehicleIx >= 0 && vehicleIx < deal.order.length ? deal.order[vehicleIx] : null;
  bool get roundDone => why != null;
  bool get done => stage == M7HandStage.done;
  bool get allGone => vehicleIx >= deal.order.length;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get thorough => stepSlips == 0;

  List<M7Waste> at(M7Spot s) => [for (final w in deal.items) if (spot[w] == s) w];
  bool _left(M7Kind k) => at(M7Spot.trolley).any((w) => w.kind == k);

  /// Lamps boxed (or cracked) and the oily waste in the red bin: the vehicles may come.
  bool get prepDone => stage == M7HandStage.prep && !roundDone && !_left(M7Kind.lamp) && !_left(M7Kind.oily);

  /// Waste that still waits for its vehicle.
  List<M7Waste> get pending => [
        for (final w in deal.items)
          if (w.kind != M7Kind.oily && const {M7Spot.trolley, M7Spot.lampBox, M7Spot.greenBin}.contains(spot[w])) w,
      ];

  void _tag(String s) {
    if (!caught.contains(s)) caught.add(s);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stepSlips++;
    return m;
  }

  M7Drop _slipDrop(DoMistake m, {bool cracked = false}) => M7Drop(M7DropKind.slip, mistake: _slip(m), cracked: cracked);

  /// The first vehicle pulls in.
  void startVehicles() {
    if (stage != M7HandStage.prep) return;
    stage = M7HandStage.vehicle;
    vehicleIx = 0;
    here = false;
  }

  /// The vehicle at the gate has pulled in and its driver waits.
  void arrived() {
    if (stage == M7HandStage.vehicle && vehicle != null) here = true;
  }

  /// The next vehicle (or the end of them).
  void advance() {
    here = false;
    bed.clear();
    dumped.clear();
    vehicleIx++;
  }

  /// A release of [p] on [t].
  M7Drop drop(M7Piece p, M7Place t) {
    if (done || roundDone) return M7Drop.back;
    switch (p.kind) {
      case M7PieceKind.item:
        return _dropItem(p.w!, t);
      case M7PieceKind.lampBox:
        return _dropGroup(at(M7Spot.lampBox), M7Kind.lamp, t);
      case M7PieceKind.redBin:
        return _dropGroup(at(M7Spot.redBin), M7Kind.oily, t);
      case M7PieceKind.greenBin:
        return _dropGroup(at(M7Spot.greenBin), M7Kind.general, t);
    }
  }

  M7Drop _dropGroup(List<M7Waste> ws, M7Kind cls, M7Place t) {
    if (ws.isEmpty || t != M7Place.bed || !here) return M7Drop.back;
    return _hand(ws, cls);
  }

  M7Drop _dropItem(M7Waste w, M7Place t) {
    if (spot[w] != M7Spot.trolley) return M7Drop.back;
    final onBed = t == M7Place.bed && here;
    switch (w.kind) {
      case M7Kind.lamp:
        if (t == M7Place.lampBox) {
          spot[w] = M7Spot.lampBox;
          if (!lampsAsked && !_left(M7Kind.lamp)) {
            lampsAsked = true;
            _ask(M7HandWhy.lamps, M7WasteHandoverLines.caughtLamps);
          }
          return const M7Drop(M7DropKind.placed);
        }
        if (t == M7Place.trolley) return M7Drop.back;
        spot[w] = M7Spot.cracked;
        return _slipDrop(M7WasteHandoverMistakes.lampCrack, cracked: true);
      case M7Kind.oily:
        if (t == M7Place.redBin) {
          spot[w] = M7Spot.redBin;
          if (!oilyAsked && !_left(M7Kind.oily)) {
            oilyAsked = true;
            _ask(M7HandWhy.oily, M7WasteHandoverLines.caughtOily);
          }
          return const M7Drop(M7DropKind.placed);
        }
        if (t == M7Place.greenBin) return _slipDrop(M7WasteHandoverMistakes.oilyGreen);
        return onBed ? _hand([w], M7Kind.oily) : M7Drop.back;
      case M7Kind.general:
        if (t == M7Place.greenBin) {
          spot[w] = M7Spot.greenBin;
          return const M7Drop(M7DropKind.placed);
        }
        return onBed ? _hand([w], M7Kind.general) : M7Drop.back;
      case M7Kind.oil || M7Kind.elec:
        if (t == M7Place.greenBin) return _slipDrop(M7WasteHandoverMistakes.hazGreen);
        return onBed ? _hand([w], w.kind) : M7Drop.back;
    }
  }

  void _ask(M7HandWhy w, String tag) {
    why = w;
    whyDeparture = false;
    _tag(tag);
  }

  /// A load of one kind put on the bed of the vehicle at the bay.
  M7Drop _hand(List<M7Waste> ws, M7Kind cls) {
    final v = vehicle;
    if (v == null) return M7Drop.back;
    if (v == M7Vehicle.unmarked) {
      for (final w in ws) {
        spot[w] = M7Spot.lost;
      }
      here = false;
      return M7Drop(M7DropKind.vanLeaves, mistake: _slip(M7WasteHandoverMistakes.vanTake));
    }
    if (m7HandReceiver(cls) == v) {
      for (final w in ws) {
        spot[w] = M7Spot.loaded;
      }
      bed.addAll(ws);
      return const M7Drop(M7DropKind.loaded);
    }
    if (v == M7Vehicle.municipal) return _slipDrop(M7WasteHandoverMistakes.hazMunicipal);
    return _slipDrop(switch (cls) {
      M7Kind.oil => M7WasteHandoverMistakes.wrongOil,
      M7Kind.elec => M7WasteHandoverMistakes.wrongElec,
      M7Kind.lamp => M7WasteHandoverMistakes.wrongLamp,
      M7Kind.oily => M7WasteHandoverMistakes.wrongRed,
      M7Kind.general => M7WasteHandoverMistakes.wrongGeneral,
    });
  }

  /// The "যান" tab: the vehicle at the bay is sent off.
  M7Depart? depart() {
    final v = vehicle;
    if (!here || roundDone || stage != M7HandStage.vehicle || v == null) return null;
    here = false;
    if (v == M7Vehicle.unmarked) {
      _tag(M7WasteHandoverLines.caughtVan);
      why = M7HandWhy.van;
      whyDeparture = true;
      return M7Depart(why);
    }
    if (bed.isEmpty) {
      wavedEmpty.add(v);
      return const M7Depart(null);
    }
    handed.add(v);
    _tag(switch (v) {
      M7Vehicle.recycler => M7WasteHandoverLines.caughtOil,
      M7Vehicle.collection => M7WasteHandoverLines.caughtElec,
      M7Vehicle.disposal => M7WasteHandoverLines.caughtBox,
      _ => M7WasteHandoverLines.caughtGeneral,
    });
    why = m7HandWhyOf(v);
    whyDeparture = true;
    return M7Depart(why);
  }

  /// The reason is paid; true when it was the vehicle's own (the next one comes).
  bool paid() {
    final dep = whyDeparture;
    why = null;
    whyDeparture = false;
    stepSlips = 0;
    return dep;
  }

  /// After the last vehicle: waste still waiting = one slip.
  DoMistake? finalCheck() {
    if (done) return null;
    stage = M7HandStage.done;
    return pending.isEmpty ? null : _slip(M7WasteHandoverMistakes.undelivered);
  }

  /// Listened to him (a slip): the dealt hazardous item goes onto the municipal truck.
  DoMistake listen() {
    final bad = <M7Waste>[
      ...at(M7Spot.trolley).where((w) => w.kind == M7Kind.elec),
      ...at(M7Spot.lampBox),
      ...at(M7Spot.trolley).where((w) => w.kind == M7Kind.oil),
      ...at(M7Spot.redBin),
    ];
    final first = bad.isEmpty ? null : bad.first;
    final group = first == null
        ? const <M7Waste>[]
        : switch (spot[first]!) {
            M7Spot.lampBox => at(M7Spot.lampBox),
            M7Spot.redBin => at(M7Spot.redBin),
            _ => [first],
          };
    for (final w in group) {
      spot[w] = M7Spot.lost;
      dumped.add(w);
    }
    return _slip(M7WasteHandoverMistakes.listen);
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 5 s).
/// ms, ~1500 per human action:
///   lamps lifted (hold 500 + drag, ×2 avg) ≈ 5000 · oily ×1–2 ≈ 2300
///   · green bin pieces ≈ 1500 · each of 4–5 vehicles: drags ≈ 2200 + "যান" ≈ 1500
///   (≈ 4 vehicles → 14800)  + a reason each (~8200 × 6.5) ≈ 53000
///   + the coworker once ≈ 9600                                      ≈ 86000–90000
/// 85 % ≈ 75000 (a builder's estimate; owner may tune after playtest).
const m7WasteHandoverQuickMs = 75000;

/// A lamp must be held this long before it lifts.
const kM7LiftMs = 500;

/// How far above the finger the held piece is drawn (and released).
const kM7HeldLift = 26.0;

@immutable
class M7WasteHandoverPack {
  const M7WasteHandoverPack({required this.id, required this.titleBn, this.quickMs = m7WasteHandoverQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M7WasteHandoverPack> m7WasteHandoverPacks = {
  'do_7_8_b': M7WasteHandoverPack(id: 'do_7_8_b', titleBn: M7WasteHandoverLines.title),
};

/// Test hook: the play on screen (tests only read it).
abstract final class M7WasteHandoverProbe {
  static M7HandRun? run;
}

// ============================================================================
// Page
// ============================================================================

class M7WasteHandoverPage extends StatefulWidget {
  const M7WasteHandoverPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M7WasteHandoverPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M7WasteHandoverPage> createState() => _M7WasteHandoverPageState();
}

class _M7WasteHandoverPageState extends State<M7WasteHandoverPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _HandRunPage(
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

/// What follows the card now up.
enum _After { none, vanLeaves, finish }

class _HandRunPage extends ConsumerStatefulWidget {
  const _HandRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M7WasteHandoverPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_HandRunPage> createState() => _HandRunPageState();
}

class _HandRunPageState extends ConsumerState<_HandRunPage> with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M7HandRun _run;
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _after = _After.none;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;

  /// The vehicle on screen (coming in, waiting or leaving) and its drive.
  M7Vehicle? _shown;
  var _arriving = false;
  var _leaving = false;
  late final AnimationController _vehCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100), value: 1);
  Timer? _driveTimer;
  VoidCallback? _afterLeave;

  /// The finger: the piece under it at the touch, the piece being carried, and where.
  M7Piece? _cand;
  M7Piece? _drag;
  Offset _dragAt = Offset.zero;

  /// A lamp being held to lift it (the ring), and the lamp lifted.
  M7Waste? _holdLamp;
  M7Waste? _lifted;
  Timer? _holdTimer;
  int _holdN = 0;
  M7Waste? _touchedLamp;
  int _liftSaid = 0;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  final Map<M7Waste, GlobalKey> _itemKeys = {for (final w in M7Waste.values) w: GlobalKey()};
  final _lampBoxKey = GlobalKey();
  final _redKey = GlobalKey();
  final _greenKey = GlobalKey();
  final _yanKey = GlobalKey();
  int _hintN = 0;
  int _steps = 0;
  M7HandGeo? _geoNow;

  @override
  void initState() {
    super.initState();
    _run = M7HandRun(m7HandDeal(widget.rng));
    M7WasteHandoverProbe.run = _run;
  }

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chain++;
    _holdTimer?.cancel();
    _driveTimer?.cancel();
    _vehCtl.dispose();
    if (identical(M7WasteHandoverProbe.run, _run)) M7WasteHandoverProbe.run = null;
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

  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_arriving && !_leaving;

  String get _task => M7WasteHandoverLines.task(_run.stage, arriving: _arriving || (_run.stage == M7HandStage.vehicle && !_run.here));

  /// His window: once he is due, the decisive controls wait for him.
  bool _waitForHim() => coworkerDue && holdForCoworker();

  void _changed() {
    _steps++;
    setState(() {});
  }

  // --- the start and the vehicles --------------------------------------------------
  Future<void> _start() async {
    _clock.start();
    setState(() {});
    unawaited(_sayChain([_task]));
  }

  /// Between beats: the vehicles come once the sorting is done.
  void _pump() {
    if (!mounted || _ended || _card != null || tableBusy || coworkerOpen || _arriving || _leaving) return;
    if (_run.stage == M7HandStage.prep && _run.prepDone) {
      _run.startVehicles();
      _arrive();
    }
  }

  void _arrive() {
    final v = _run.vehicle;
    if (v == null) return;
    _hush();
    setState(() {
      _shown = v;
      _arriving = true;
      _steps++;
    });
    _cue('sounds/intro/click.ogg', volume: 0.4);
    void arrived() {
      if (!mounted || _ended) return;
      _run.arrived();
      setState(() {
        _arriving = false;
        _steps++;
      });
      if (v == M7Vehicle.municipal && !coworkerDone && !coworkerDue) scheduleCoworker();
      if (!tableBusy && _card == null) unawaited(_sayChain([_task]));
    }

    if (_quiet) {
      _vehCtl.value = 1;
      _driveTimer = Timer(const Duration(milliseconds: 300), arrived);
    } else {
      _vehCtl.value = 0;
      _vehCtl.duration = const Duration(milliseconds: 1100);
      unawaited(_vehCtl.forward().whenComplete(arrived));
    }
  }

  /// The vehicle drives off (what it carries goes with it).
  void _leave() {
    if (_shown == null) return;
    setState(() {
      _leaving = true;
      _steps++;
    });
    void gone() {
      if (!mounted) return;
      setState(() {
        _leaving = false;
        _shown = null;
        _steps++;
      });
      final f = _afterLeave;
      _afterLeave = null;
      f?.call();
    }

    if (_quiet) {
      _driveTimer = Timer(const Duration(milliseconds: 300), gone);
    } else {
      _vehCtl.value = 0;
      unawaited(_vehCtl.forward().whenComplete(gone));
    }
  }

  /// The next vehicle, or the end of them (waits while one is still driving off).
  void _afterVehicle() {
    if (!mounted || _ended) return;
    if (_leaving) {
      _afterLeave = _afterVehicle;
      return;
    }
    _run.advance();
    if (_run.allGone) {
      _endCheck();
    } else {
      _arrive();
    }
  }

  void _endCheck() {
    final m = _run.finalCheck();
    if (m != null) {
      _after = _After.finish;
      unawaited(_mistake(m, _centre));
      return;
    }
    unawaited(_finish());
  }

  Offset get _centre {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height * 0.45);
  }

  // --- the touch: lift, carry, release -----------------------------------------------
  M7Piece? _pieceAt(Offset p, M7HandGeo geo) {
    final r = _run;
    if (geo.lampBox.contains(p) && r.at(M7Spot.lampBox).isNotEmpty) return const M7Piece.box(M7PieceKind.lampBox);
    if (geo.redBin.contains(p) && r.at(M7Spot.redBin).isNotEmpty) return const M7Piece.box(M7PieceKind.redBin);
    if (geo.greenBin.contains(p) && r.at(M7Spot.greenBin).isNotEmpty) return const M7Piece.box(M7PieceKind.greenBin);
    for (final w in r.at(M7Spot.trolley)) {
      if (geo.slot(r.deal.slotOf[w]!).inflate(1).contains(p)) return M7Piece.item(w);
    }
    return null;
  }

  void _down(Offset p) {
    _cand = null;
    final geo = _geoNow;
    if (geo == null || !_canPlay) return;
    final c = _cand = _pieceAt(p, geo);
    final w = c?.w;
    if (c == null || w == null || w.kind != M7Kind.lamp) return;
    _touchedLamp = w;
    _holdLamp = w;
    _lifted = null;
    _holdN++;
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: kM7LiftMs), () {
      _holdTimer = null;
      if (!mounted || _holdLamp != w) return;
      HapticFeedback.mediumImpact();
      setState(() => _lifted = w);
    });
    setState(() {});
  }

  void _cancelLift() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (!mounted) return;
    if (_holdLamp != null || _lifted != null) {
      setState(() {
        _holdLamp = null;
        _lifted = null;
      });
    }
  }

  void _panStart(Offset p) {
    final c = _cand;
    if (c == null || !_canPlay) return;
    final w = c.w;
    if (w != null && w.kind == M7Kind.lamp && _lifted != w) {
      // Slid before the lamp was lifted: it stays (how to lift is the line).
      _cancelLift();
      _tick();
      if (_liftSaid < 2) {
        _liftSaid++;
        unawaited(_sayChain([M7WasteHandoverLines.liftHow]));
      }
      return;
    }
    if (_waitForHim()) {
      _cancelLift();
      return;
    }
    setState(() {
      _drag = c;
      _dragAt = p;
    });
  }

  void _panUpdate(Offset p) {
    if (_drag == null) return;
    if (!_canPlay) {
      setState(() => _drag = null);
      return;
    }
    setState(() => _dragAt = p);
  }

  void _panEnd(Offset global) {
    final piece = _drag;
    final geo = _geoNow;
    final at = _dragAt;
    _cancelLift();
    if (piece == null || geo == null) return;
    setState(() => _drag = null);
    if (!_canPlay) return;
    final place = geo.placeAt(at.translate(0, -kM7HeldLift), bedOpen: _run.here && !_leaving && !_arriving);
    _drop(piece, place, global);
  }

  void _panCancel() {
    _cancelLift();
    if (_drag != null) setState(() => _drag = null);
  }

  void _drop(M7Piece piece, M7Place place, Offset global) {
    final r = _run.drop(piece, place);
    switch (r.kind) {
      case M7DropKind.back:
        _hints.missTap();
      case M7DropKind.placed:
        _cue('sounds/intro/click.ogg', volume: 0.45);
        HapticFeedback.mediumImpact();
        _changed();
        if (_run.why != null) _askStep();
      case M7DropKind.loaded:
        _cue('sounds/intro/click.ogg', volume: 0.5);
        HapticFeedback.mediumImpact();
        _changed();
      case M7DropKind.slip:
        _changed();
        unawaited(_mistake(r.mistake!, global));
      case M7DropKind.vanLeaves:
        _changed();
        _after = _After.vanLeaves;
        unawaited(_mistake(r.mistake!, global));
    }
  }

  void _yanTap() {
    if (!_canPlay || !_run.here) {
      _hints.missTap();
      return;
    }
    if (_waitForHim()) return;
    final d = _run.depart();
    if (d == null) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.6);
    _changed();
    _leave();
    if (d.why != null) {
      _askStep();
    } else {
      _afterLeave = _afterVehicle;
    }
  }

  // --- the success beat -----------------------------------------------------------
  void _askStep() {
    final w = _run.why;
    if (w == null) return;
    _hush();
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final s = _steps;
    unawaited(askReason(
      deal: () => dealChoices(M7WasteHandoverLines.whyRight[w]!, M7WasteHandoverLines.myths, widget.rng),
      question: M7WasteHandoverLines.whyQ[w]!,
      stillValid: () => !_ended && _run.why == w && _steps == s,
    ));
  }

  Future<void> _mistake(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
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
      final dep = _run.paid();
      setState(() => _steps++);
      if (dep) {
        _afterVehicle();
      } else {
        _pump();
        if (_run.stage == M7HandStage.prep && !_arriving) unawaited(_sayChain([_task]));
      }
    }));
  }

  // --- the pressure moment -------------------------------------------------------
  @override
  CoworkerScript get coworkerScript => M7WasteHandoverLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended) return null;
    final r = _run;
    if (r.stage != M7HandStage.vehicle || r.vehicle != M7Vehicle.municipal || !r.here || r.roundDone) return null;
    if (_intro || _card != null || tableBusy || _drag != null || _arriving || _leaving) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    final p = _run.deal.push;
    if (!held) {
      final m = _run.listen();
      setState(() => _steps++);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M7WasteHandoverLines.caughtNo);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M7WasteHandoverLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M7WasteHandoverLines.tapWhy[_nudgeN++ % M7WasteHandoverLines.tapWhy.length]
            : _nudge.next(_task);
    _tick('sounds/intro/tick.ogg', 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes -------------------------------------------------------------------
  Future<void> _struckOut(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _hush();
    _clock.stop();
    _holdTimer?.cancel();
    _driveTimer?.cancel();
    _vehCtl.stop();
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
    _cancelLift();
    setState(() {
      _card = m;
      _drag = null;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m7hand/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() => _card = null);
    final after = _after;
    _after = _After.none;
    switch (after) {
      case _After.vanLeaves:
        _afterLeave = _afterVehicle;
        _leave();
        return;
      case _After.finish:
        unawaited(_finish());
        return;
      case _After.none:
        break;
    }
    if (_run.why != null) {
      _askStep();
      return;
    }
    unawaited(_sayChain([_task]));
    _pump();
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
    await _say(!_run.passed ? M7WasteHandoverLines.fail : (_quickBonus ? M7WasteHandoverLines.quick : M7WasteHandoverLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leaveLevel() async {
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the gesture hand -----------------------------------------------------------
  /// How to touch, never what: a hold ring on a lamp he just touched (how to
  /// lift it); otherwise a sweep over the trolley's waste, the lamp box, both
  /// bins and (with a vehicle in) the "যান" tab alike, or a short sideways
  /// nudge of one piece of waste on the trolley (never toward the vehicle).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final r = _run;
    final tl = _touchedLamp;
    if (tl != null && r.spot[tl] == M7Spot.trolley) {
      _touchedLamp = null;
      final h = HintSpec.holdOn(_itemKeys[tl]!);
      if (h != null) return h;
    }
    final onTrolley = r.at(M7Spot.trolley);
    if (n.isOdd && onTrolley.isNotEmpty) {
      final plain = [for (final w in onTrolley) if (w.kind != M7Kind.lamp) w];
      final w = (plain.isEmpty ? onTrolley : plain)[widget.rng.nextInt(plain.isEmpty ? onTrolley.length : plain.length)];
      if (w.kind == M7Kind.lamp) {
        final h = HintSpec.holdOn(_itemKeys[w]!);
        if (h != null) return h;
      } else {
        final dir = widget.rng.nextBool() ? const Offset(1, 0) : const Offset(-1, 0);
        return HintSpec.drag(geo.slot(r.deal.slotOf[w]!).center, toward: dir, travel: 56, space: HintSpace.scene);
      }
    }
    return HintSpec.sweepOver([
      for (final w in onTrolley) _itemKeys[w]!,
      _lampBoxKey,
      _redKey,
      _greenKey,
      if (r.here && !_leaving && !_arriving) _yanKey,
    ]);
  }

  // --- the scene --------------------------------------------------------------------
  double _vehDx() {
    if (_arriving) return -(1 - Curves.easeOutCubic.transform(_vehCtl.value)) * 380;
    if (_leaving) return Curves.easeIn.transform(_vehCtl.value) * 380;
    return 0;
  }

  Widget _vehicle(M7HandGeo geo) {
    final v = _shown!;
    final r = _run;
    final shift = geo.bay.topLeft;
    final loads = [...r.bed, ...r.dumped];
    final body = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: M7VehiclePainter(v)))),
        for (final (i, w) in loads.indexed)
          Positioned.fromRect(
            key: ValueKey('load-${w.name}'),
            rect: geo.bedItem(i).shift(-shift),
            child: IgnorePointer(child: CustomPaint(painter: M7WastePainter(w))),
          ),
      ],
    );
    return Semantics(
      label: M7WasteHandoverLines.vehicleLabel(v),
      child: AnimatedBuilder(
        animation: _vehCtl,
        child: body,
        builder: (_, child) => Transform.translate(offset: Offset(_vehDx(), 0), child: child),
      ),
    );
  }

  Widget _boxWidget(M7BoxKind kind, Rect rect, GlobalKey key, String label) {
    final r = _run;
    final fill = switch (kind) {
      M7BoxKind.lampBox => r.at(M7Spot.lampBox).length,
      M7BoxKind.redBin => r.at(M7Spot.redBin).length,
      M7BoxKind.greenBin => r.at(M7Spot.greenBin).length,
    };
    return Positioned.fromRect(
      key: ValueKey('box-${kind.name}'),
      rect: rect,
      child: Semantics(
        label: label,
        child: RepaintBoundary(key: key, child: CustomPaint(painter: M7BoxPainter(kind, fill: fill))),
      ),
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M7HandGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final r = _run;
    final carried = _drag;
    final yanUp = r.here && !_arriving && !_leaving && _card == null;
    return [
      Positioned.fill(
        key: const ValueKey('yard'),
        child: RepaintBoundary(child: CustomPaint(painter: M7HandYardPainter(geo: geo))),
      ),
      if (_shown != null) Positioned.fromRect(key: const ValueKey('vehicle'), rect: geo.bay, child: _vehicle(geo)),
      _boxWidget(M7BoxKind.lampBox, geo.lampBox, _lampBoxKey, M7WasteHandoverLines.lampBoxLabel),
      _boxWidget(M7BoxKind.redBin, geo.redBin, _redKey, M7WasteHandoverLines.redBinLabel),
      _boxWidget(M7BoxKind.greenBin, geo.greenBin, _greenKey, M7WasteHandoverLines.greenBinLabel),
      Positioned.fromRect(
        key: const ValueKey('trolley'),
        rect: geo.trolley,
        child: Semantics(label: M7WasteHandoverLines.trolleyLabel, child: const RepaintBoundary(child: CustomPaint(painter: M7HandTrolleyPainter()))),
      ),
      for (final w in r.at(M7Spot.trolley))
        if (!(carried?.w == w && carried?.kind == M7PieceKind.item))
          Positioned.fromRect(
            key: ValueKey('w-${w.name}'),
            rect: geo.slot(r.deal.slotOf[w]!),
            child: Semantics(
              label: M7WasteHandoverLines.waste(w),
              child: RepaintBoundary(key: _itemKeys[w], child: CustomPaint(painter: M7WastePainter(w))),
            ),
          ),
      // The ring that fills while a lamp is held to lift it.
      if (_holdLamp != null && r.spot[_holdLamp!] == M7Spot.trolley && _drag == null)
        Positioned.fromRect(
          key: const ValueKey('lift-ring'),
          rect: geo.slot(r.deal.slotOf[_holdLamp!]!).inflate(2),
          child: IgnorePointer(
            child: _lifted != null || quiet
                ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF9BE7A9), width: 4)))
                : TweenAnimationBuilder<double>(
                    key: ValueKey('lift-$_holdN'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: kM7LiftMs),
                    builder: (_, v, _) => CircularProgressIndicator(value: v, strokeWidth: 4, color: const Color(0xFF9BE7A9)),
                  ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M7WasteHandoverLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (_) {
              _cancelLift();
              _hints.missTap();
            },
            onPanDown: (d) => _down(d.localPosition),
            onPanStart: (d) => _panStart(d.localPosition),
            onPanUpdate: (d) => _panUpdate(d.localPosition),
            onPanEnd: (d) => _panEnd(d.globalPosition),
            onPanCancel: _panCancel,
          ),
        ),
      ),
      if (yanUp)
        Positioned.fromRect(
          key: const ValueKey('yan'),
          rect: geo.yan,
          child: Semantics(
            button: true,
            label: M7WasteHandoverLines.yanTab,
            excludeSemantics: true,
            child: GestureDetector(
              key: _yanKey,
              behavior: HitTestBehavior.opaque,
              onTap: _yanTap,
              child: const _YanTab(),
            ),
          ),
        ),
      if (carried != null)
        Positioned(
          key: const ValueKey('carried'),
          left: _dragAt.dx - (carried.kind == M7PieceKind.item ? 28 : 40),
          top: _dragAt.dy - kM7HeldLift - (carried.kind == M7PieceKind.item ? 26 : 36),
          width: carried.kind == M7PieceKind.item ? 56 : 80,
          height: carried.kind == M7PieceKind.item ? 52 : 74,
          child: IgnorePointer(
            child: carried.kind == M7PieceKind.item
                ? CustomPaint(painter: M7WastePainter(carried.w!))
                : CustomPaint(
                    painter: M7BoxPainter(
                      switch (carried.kind) {
                        M7PieceKind.lampBox => M7BoxKind.lampBox,
                        M7PieceKind.redBin => M7BoxKind.redBin,
                        _ => M7BoxKind.greenBin,
                      },
                      fill: 1,
                    ),
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
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
    final waiting = handsOn && !tableBusy && !_arriving && !_leaving && _drag == null && _holdLamp == null && (_run.stage == M7HandStage.prep || _run.here);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leaveLevel());
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
            onClose: () => unawaited(_leaveLevel()),
            onToggleMute: () {
              unawaited(MascotSpeechLibrary.stop());
              setState(() => _muted = !_muted);
            },
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: waiting,
            hintKey: '${_run.stage.name}/${_run.vehicleIx}/$_steps',
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-$strikes'),
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
                  line: M7WasteHandoverLines.intro,
                  alarm: 'sounds/learn/siren.ogg',
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

/// The "যান" tab under the cab: tap to send the vehicle off.
class _YanTab extends StatelessWidget {
  const _YanTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E5A36),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF1E9D2), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(M7WasteHandoverLines.yanTab, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
