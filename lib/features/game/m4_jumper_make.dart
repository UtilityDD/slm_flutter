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
import 'level_juice.dart' show starsFor;
import 'level_result_parts.dart';
import 'level_shell.dart';
import 'm4_jumper_make_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm4_jumper_make_world.dart' show M4JumperMakeConn, M4JumperMakeGeo, M4JumperMakeJointPainter, M4JumperMakeShape;

// Lesson 4.2 "জাম্পার কানেকশন ও টাইট করা", কাজ 1 "জাম্পার বানাও" (pack
// do_4_2_a, engine m4_jumper_make). The line is dead: shutdown, PTW and the
// earth set on both spans (drawn; the docket says so). The trainee is up the
// dead-end pole in helmet and harness and bridges the strain string with a
// new jumper. Four stations a play:
//   ক the wire — choose a jumper piece from the coil rack and look at its cut
//     end beside the line's: the same size as the main conductor or bigger,
//     never thinner (point 1, myth 2);
//   খ the left joint and গ the right joint — the lesson's steps 1–3 in order:
//     clean both faces with the steel brush, the anti-oxidant paste (the
//     jumper is aluminium), the right connector (by the conductor's material:
//     the aluminium PG clamp; where the right span is an old copper conductor,
//     the bi-metallic one — pro tip 3), then tighten with two spanners (one
//     holds the bolt's head, the other turns the nut — pro tip 1); every
//     tray carries the same four connectors (PG Al, PG Cu, bi-metallic, a
//     twist of binding wire), so the bi-metallic one never marks the copper
//     joint; the careless coworker pushes "no brush, just put it on" at the
//     right joint, before its brush (the brush, the paste and the tray wait
//     for him), never after it;
//   ঘ the shape — a smooth U, long enough to stay clear of the cross-arm in a
//     strong wind, not pulled straight (step 4); then no sharp edge: a strand
//     sticking out of the cut end is trimmed (film rule 3, corona).
//
// No deadly move (the line is dead and earthed). Slips: a thin piece, a
// connector before the brush, before the paste, the wrong metal (a copper PG
// or a bi-metallic on aluminium), no bi-metallic on copper, a twisted joint,
// one spanner, the jumper pulled straight, too long, done with a sharp
// strand, listening to him. Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m4_jumper_make_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next station by itself; the coworker once a play. Voice: the
// guide's lines by device TTS; the coworker's push is silent with its caption
// held until it is recorded in his voice (his exit line is recorded). Gesture
// hints: a sweep over the choices on screen in every waiting state (never a
// tap on the right one).

// ============================================================================
// Content
// ============================================================================

enum M4JumperMakeStation { wire, joint1, joint2, shape }

abstract final class M4JumperMakeLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askWire, askJoint1, askJoint2, askTight, askShape, askFinish];

  static const title = 'জাম্পার বানাও';
  static const intro = 'লাইন বন্ধ, আর্থ লাগানো। এবার নতুন জাম্পার বানান — ঠিক তার, পরিষ্কার জোড়া!';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];

  static const askWire = 'জাম্পারের জন্য তার বাছুন।';
  static const askJoint1 = 'বাঁ দিকের জোড়াটা লাগান।';
  static const askJoint2 = 'এবার ডান দিকের জোড়াটা লাগান।';
  static const askTight = 'ক্ল্যাম্প বসেছে — এবার টাইট দিন।';
  static const askShape = 'জাম্পারটাকে আকার দিন।';
  static const askFinish = 'জোড়াটা দেখে নিয়ে কাজ শেষ করুন।';
  static String ask(M4JumperMakeStation s, {bool fitted = false, bool shaped = false}) => switch (s) {
        M4JumperMakeStation.wire => askWire,
        M4JumperMakeStation.joint1 => fitted ? askTight : askJoint1,
        M4JumperMakeStation.joint2 => fitted ? askTight : askJoint2,
        M4JumperMakeStation.shape => shaped ? askFinish : askShape,
      };
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'ডেড-এন্ড পোল';
  static const lineWire = 'লাইনের তার';
  static const thisPiece = 'এই টুকরো';
  static const take = 'এটা নেব';
  static const putBack = 'রেখে দিই';
  static String piece(int i) => 'জাম্পার টুকরো ${i + 1}';
  static const brush = 'স্টিল ব্রাশ';
  static const paste = 'পেস্ট';
  static const oneWrench = 'এক রেঞ্চে টাইট';
  static const twoWrench = 'দুই রেঞ্চে টাইট';
  static const finish = 'কাজ শেষ';
  static const strand = 'বেরিয়ে থাকা তার';
  static String conn(M4JumperMakeConn c) => switch (c) {
        M4JumperMakeConn.pgAl => 'PG · Al',
        M4JumperMakeConn.pgCu => 'PG · Cu',
        M4JumperMakeConn.bimetal => 'বাই-মেটালিক',
        M4JumperMakeConn.twist => 'বাঁধাই তার',
      };
  static String shape(M4JumperMakeShape s) => switch (s) {
        M4JumperMakeShape.tight => 'আকার 1',
        M4JumperMakeShape.smooth => 'আকার 2',
        M4JumperMakeShape.long => 'আকার 3',
      };
  static const docket = 'ডকেট';
  static const job = 'নতুন জাম্পার';
  static String line(bool acsr) => acsr ? 'লাইন: ACSR' : 'লাইন: AAAC';
  static String material(bool acsr) => acsr ? 'ACSR' : 'AAAC';
  static const copperSide = 'ডান পাশে তামার তার';
  static const permit = 'শাটডাউন · PTW · আর্থ';
  static const stampDone = 'জাম্পার তৈরি';

  // The reasons (lesson 4.2): the right ones state this station's rule; the
  // wrong ones are field excuses — never a true rule marked wrong.
  static const whyWire = 'এই তারটাই কেন নিলেন?';
  static const whyJoint = 'জোড়াটা এভাবে কেন লাগালেন?';
  static const whyShape = 'জাম্পারকে এই আকার কেন দিলেন?';
  static String why(M4JumperMakeStation s) => switch (s) {
        M4JumperMakeStation.wire => whyWire,
        M4JumperMakeStation.joint1 || M4JumperMakeStation.joint2 => whyJoint,
        M4JumperMakeStation.shape => whyShape,
      };

  static const wireWhy = [
    'জাম্পার মূল তারের সমান বা মোটা হতে হয়',
    'সরু জাম্পার বেশি লোডে গরম হয়ে গলে যায়',
    'লাইনের পুরো কারেন্ট জাম্পার দিয়েই যায়',
  ];
  static const jointWhy = [
    'ময়লা থাকলে ভালো কানেক্টরও ব্যর্থ হয়',
    'অ্যালুমিনিয়ামে ব্রাশের পর পেস্ট দিতে হয়',
    'দুই রেঞ্চে ধরলে ক্ল্যাম্প ঠিক চেপে বসে',
  ];
  static const copperWhy = [
    'তামা-অ্যালুমিনিয়ামে বাই-মেটালিক লাগে',
    'বাই-মেটালিক গ্যালভানিক ক্ষয় আটকায়',
    'আলাদা ধাতুর জোড়ায় সাধারণ PG চলে না',
  ];
  static const shapeWhy = [
    'জাম্পারকে মসৃণ U বা C আকার দিতে হয়',
    'ক্রস-আর্মে যেন না ঠেকে, তাই মাপমতো লম্বা',
    'ধারালো প্রান্তে করোনা হয়, তাই সব মসৃণ',
  ];
  static List<String> whyRight(M4JumperMakeStation s, {bool copper = false}) => switch (s) {
        M4JumperMakeStation.wire => wireWhy,
        M4JumperMakeStation.joint1 => jointWhy,
        M4JumperMakeStation.joint2 => copper ? copperWhy : jointWhy,
        M4JumperMakeStation.shape => shapeWhy,
      };

  /// Field excuses (wrong on every deck).
  static const excuses = [
    'তাড়াতাড়ি শেষ হবে, তাই এভাবেই করলাম',
    'সবাই তো এভাবেই করে, কিছুই হয় না',
    'জাম্পারে তো টান নেই, যা খুশি চলে',
    'হাতের কাছে যে তার ছিল সেটাই নিলাম',
    'সুপারভাইজার দেখছেন না, এতেই চলবে',
    'ঢিলা থাকলেও কারেন্ট ঠিক চলে যায়',
  ];

  /// The careless coworker: no brushing (pro tip 4: cleanliness is the key).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'ব্রাশ-ট্রাশ লাগবে না, সোজা লাগিয়ে দাও!',
    exitLine: coworkerExit,
    right: ['না, আগে ব্রাশে ঘষে পরিষ্কার করে নেব', 'না, ময়লা থাকলে কানেক্টর ব্যর্থ হয়', 'না, পরিষ্কার না করলে জোড়া টিকবে না'],
    wrong: ['ঠিক, ব্রাশ ছাড়াই এখনই লাগিয়ে দিই', 'আচ্ছা, সোজা ক্ল্যাম্পটা বসিয়ে দিই', 'নতুন তার তো, ময়লা থাকার কথা না', 'টাইট দিলেই সব ঠিক হয়ে যাবে', 'ঠিক আছে, ব্রাশ পরের বার করব'],
    asks: ['ও বলছে ব্রাশ ছাড়াই লাগাতে। আপনি কী করবেন?', 'ব্রাশ করবেন, না সোজা লাগাবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  static const allSet = 'জাম্পার তৈরি — ঠিক সাইজ, পরিষ্কার জোড়া, দুই রেঞ্চে টাইট, মসৃণ U।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ঠিক তার, আগে পরিষ্কার, তারপর জোড়া।';

  // "আজ যা ধরলেন".
  static const caughtWire = 'মূল তারের সমান বা মোটা জাম্পার';
  static const caughtClean = 'ব্রাশে ঘষে, পেস্ট দিয়ে জোড়া';
  static const caughtBimetal = 'তামা-অ্যালুমিনিয়ামে বাই-মেটালিক';
  static const caughtWrench = 'দুই রেঞ্চে টাইট';
  static const caughtShape = 'মসৃণ U, ক্রস-আর্ম থেকে দূরে';
  static const caughtEdge = 'ধারালো তারের মাথা মসৃণ করেছেন';
  static const caughtCall = 'চাপে “না” — আগে ব্রাশ';
}

abstract final class M4JumperMakeMistakes {
  static const _dir = 'assets/game/art/m4_jumper_make';

  static const thinWire = DoMistake(
    key: '4.2/m4_jumper_make/thin-jumper',
    textBn: 'এই টুকরোটা লাইনের তারের চেয়ে সরু। জাম্পারের সাইজ মূল কন্ডাক্টরের সমান বা বেশি হতে হবে — সরু জাম্পার ওভারলোডে গরম হয়ে গলে যায়।',
    art: '$_dir/thin.svg',
    lessonPoint: 0,
  );
  static const noClean = DoMistake(
    key: '4.2/m4_jumper_make/no-brush',
    textBn: 'পরিষ্কার না করেই এগোলেন। সংযোগের আগে জাম্পার আর মূল তারের পৃষ্ঠ স্টিল ব্রাশে ভালো করে ঘষে অক্সাইড-ময়লা তুলুন — নইলে সবচেয়ে ভালো কানেক্টরও ব্যর্থ হয়।',
    art: '$_dir/brush.svg',
    lessonPoint: 1,
  );
  static const noPaste = DoMistake(
    key: '4.2/m4_jumper_make/no-paste',
    textBn: 'পেস্ট বাদ পড়ল। অ্যালুমিনিয়ামের তার ব্রাশে পরিষ্কার করার পর অ্যান্টি-অক্সিডেন্ট পেস্ট লাগান, তারপর কানেক্টর।',
    art: '$_dir/paste.svg',
    lessonPoint: 1,
  );
  static const wrongMetal = DoMistake(
    key: '4.2/m4_jumper_make/copper-clamp-on-aluminium',
    textBn: 'দুই পাশই অ্যালুমিনিয়াম, অথচ তামার কানেক্টর নিলেন। কন্ডাক্টরের মেটেরিয়াল (ACSR/AAAC) অনুযায়ী কানেক্টর বাছুন — এখানে অ্যালুমিনিয়ামের PG ক্ল্যাম্প।',
    art: '$_dir/metal.svg',
    lessonPoint: 1,
  );

  /// Both sides aluminium, the bi-metallic connector taken (step 1: by the
  /// conductors' metal).
  static const bimetalOnAl = DoMistake(
    key: '4.2/m4_jumper_make/bimetallic-on-aluminium',
    textBn: 'দুই পাশই অ্যালুমিনিয়াম — এখানে বাই-মেটালিক কানেক্টর নয়। কন্ডাক্টরের মেটেরিয়াল (ACSR/AAAC) অনুযায়ী কানেক্টর বাছুন — এখানে অ্যালুমিনিয়ামের PG ক্ল্যাম্প।',
    art: '$_dir/metal.svg',
    lessonPoint: 1,
  );

  /// Pro tip 3: the pro tips are not a lesson point (no "পাঠে দেখুন").
  static const noBimetal = DoMistake(
    key: '4.2/m4_jumper_make/no-bimetallic',
    textBn: 'তামার তারের সাথে অ্যালুমিনিয়ামের জাম্পার — এখানে বাই-মেটালিক কানেক্টর লাগবেই। সাধারণ ক্ল্যাম্পে গ্যালভানিক করোশন হয়।',
    art: '$_dir/bimetal.svg',
  );
  static const twist = DoMistake(
    key: '4.2/m4_jumper_make/twisted-joint',
    textBn: 'তার পেঁচিয়ে বাঁধা কোনো কানেক্টর নয়। সঠিক কানেক্টর — PG ক্ল্যাম্প বা কম্প্রেশন কানেক্টর — ব্যবহার করুন; তাড়াহুড়োর জোড়াই পরে হটস্পট হয়।',
    art: '$_dir/twist.svg',
    lessonPoint: 1,
  );

  /// Pro tip 1.
  static const oneWrench = DoMistake(
    key: '4.2/m4_jumper_make/one-wrench',
    textBn: 'এক রেঞ্চে টাইট দিলেন। একটি রেঞ্চে বোল্টের মাথা ধরে রাখুন, অন্যটি দিয়ে নাট ঘোরান — তাতেই কানেক্টর ঠিকমতো চেপে বসে।',
    art: '$_dir/wrench.svg',
  );
  static const tightShape = DoMistake(
    key: '4.2/m4_jumper_make/pulled-straight',
    textBn: 'জাম্পার টানটান সোজা করলেন। জাম্পারকে মসৃণ U বা C আকৃতি দিন — ঠিকমতো না বাঁকালে বাতাসে দুলে বিপদ হতে পারে।',
    art: '$_dir/straight.svg',
    lessonPoint: 1,
  );
  static const longShape = DoMistake(
    key: '4.2/m4_jumper_make/too-long',
    textBn: 'জাম্পার বেশি লম্বা — প্রবল বাতাসে দুলে ক্রস-আর্ম বা পাশের ফেজে ঠেকতে পারে। দৈর্ঘ্য এমন রাখুন যাতে দুললেও কিছু স্পর্শ না করে।',
    art: '$_dir/long.svg',
    lessonPoint: 1,
  );

  /// The film's field rule 3 (the lesson's advanced fact on corona).
  static const sharpEnd = DoMistake(
    key: '4.2/m4_jumper_make/sharp-strand',
    textBn: 'একটা তার খোঁচা হয়ে বেরিয়ে আছে। কোনো ধারালো প্রান্ত রাখবেন না — করোনা ডিসচার্জ হয়ে টিভি-রেডিওতে নয়েজ তৈরি হয়।',
    art: '$_dir/sharp.svg',
  );

  static List<DoMistake> get all => const [thinWire, noClean, noPaste, wrongMetal, bimetalOnAl, noBimetal, twist, oneWrench, tightShape, longShape, sharpEnd];
}

/// One play: the pieces on the rack, the line's conductor, which side is
/// copper, the connectors on the tray at each joint, the order of the bends,
/// whether a strand sticks out of a cut end.
@immutable
class M4JumperMakeDeal {
  const M4JumperMakeDeal({
    required this.pieces,
    required this.acsr,
    required this.copperRight,
    required this.tray1,
    required this.tray2,
    required this.shapes,
    required this.stray,
    this.brushFirst = true,
    this.twoWrenchFirst = false,
  });

  /// Each piece's size relative to the line's conductor (≥ 1 is right).
  final List<double> pieces;

  /// The line's conductor: ACSR (steel core) or AAAC.
  final bool acsr;
  final bool copperRight;
  final List<M4JumperMakeConn> tray1;
  final List<M4JumperMakeConn> tray2;
  final List<M4JumperMakeShape> shapes;
  final bool stray;

  /// The tool row's order at the joints (left to right): the brush or the
  /// paste first, and one spanner or two first. Shuffled per play so the
  /// layout never reads out the right order.
  final bool brushFirst;
  final bool twoWrenchFirst;
}

M4JumperMakeDeal m4JumperMakeDeal(math.Random rng) {
  final rights = rng.nextBool() ? [1.0, 1.3] : [rng.nextBool() ? 1.0 : 1.3];
  final thin = [0.5, 0.65, 0.8]..shuffle(rng);
  final pieces = [...rights, ...thin.take(4 - rights.length)]..shuffle(rng);
  final copper = rng.nextInt(5) < 2;
  // The same four connectors on every tray (the bi-metallic one is no clue).
  const all = M4JumperMakeConn.values;
  return M4JumperMakeDeal(
    pieces: List.unmodifiable(pieces),
    acsr: rng.nextBool(),
    copperRight: copper,
    tray1: List.unmodifiable([...all]..shuffle(rng)),
    tray2: List.unmodifiable([...all]..shuffle(rng)),
    shapes: List.unmodifiable([...M4JumperMakeShape.values]..shuffle(rng)),
    stray: rng.nextInt(3) > 0,
    brushFirst: rng.nextBool(),
    twoWrenchFirst: rng.nextBool(),
  );
}

/// The play state (pure logic).
class M4JumperMakeRun {
  M4JumperMakeRun(this.deal) : stray = deal.stray;
  final M4JumperMakeDeal deal;

  M4JumperMakeStation station = M4JumperMakeStation.wire;
  int slips = 0;
  final List<String> caught = [];

  /// Slips at the current station (a clean station pays +5).
  int stationSlips = 0;

  // wire
  int? wire;

  // the joint at hand
  bool brushed = false;
  bool pasted = false;
  M4JumperMakeConn? conn;
  bool tight = false;

  // shape
  M4JumperMakeShape? shape;
  bool stray;
  bool done = false;

  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get clean => stationSlips == 0;
  bool get atJoint => station == M4JumperMakeStation.joint1 || station == M4JumperMakeStation.joint2;

  /// The joint at hand is on the old copper span.
  bool get copperJoint => station == M4JumperMakeStation.joint2 && deal.copperRight;

  /// The connectors on the tray at this joint.
  List<M4JumperMakeConn> get tray => station == M4JumperMakeStation.joint2 ? deal.tray2 : deal.tray1;

  /// The right connector at this joint (by the conductors' metal).
  M4JumperMakeConn get rightConn => copperJoint ? M4JumperMakeConn.bimetal : M4JumperMakeConn.pgAl;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  /// Takes piece [i] for the jumper: thinner than the line's conductor = a slip.
  DoMistake? takePiece(int i) {
    if (station != M4JumperMakeStation.wire || wire != null) return null;
    if (deal.pieces[i] < 1) return _slip(M4JumperMakeMistakes.thinWire);
    wire = i;
    _tag(M4JumperMakeLines.caughtWire);
    return null;
  }

  /// The faces are brushed clean.
  void brushDone() {
    if (atJoint) brushed = true;
  }

  /// The anti-oxidant paste: before the brush = a slip.
  DoMistake? paste() {
    if (!atJoint || pasted || conn != null) return null;
    if (!brushed) return _slip(M4JumperMakeMistakes.noClean);
    pasted = true;
    return null;
  }

  /// The mistake a connector is at this joint (null: the right one).
  DoMistake? _wrongConn(M4JumperMakeConn c) {
    if (c == M4JumperMakeConn.twist) return M4JumperMakeMistakes.twist;
    if (copperJoint) return c == M4JumperMakeConn.bimetal ? null : M4JumperMakeMistakes.noBimetal;
    return switch (c) {
      M4JumperMakeConn.pgCu => M4JumperMakeMistakes.wrongMetal,
      M4JumperMakeConn.bimetal => M4JumperMakeMistakes.bimetalOnAl,
      _ => null,
    };
  }

  /// Puts connector [c] on: the wrong one, or before the brush or the paste,
  /// is a slip (it stays off).
  DoMistake? fit(M4JumperMakeConn c) {
    if (!atJoint || conn != null) return null;
    final wrong = _wrongConn(c);
    if (wrong != null) return _slip(wrong);
    if (!brushed) return _slip(M4JumperMakeMistakes.noClean);
    if (!pasted) return _slip(M4JumperMakeMistakes.noPaste);
    conn = c;
    _tag(M4JumperMakeLines.caughtClean);
    if (copperJoint) _tag(M4JumperMakeLines.caughtBimetal);
    return null;
  }

  /// Tightened with one spanner: a slip.
  DoMistake? oneWrench() {
    if (!atJoint || conn == null || tight) return null;
    return _slip(M4JumperMakeMistakes.oneWrench);
  }

  /// Tightened with two spanners; true = the joint is done.
  bool tighten() {
    if (!atJoint || conn == null || tight) return false;
    tight = true;
    _tag(M4JumperMakeLines.caughtWrench);
    return true;
  }

  /// Listened to him: on without the brush.
  DoMistake listenNoBrush() => _slip(M4JumperMakeMistakes.noClean);

  /// Bends the jumper: pulled straight or too long is a slip.
  DoMistake? bend(M4JumperMakeShape s) {
    if (station != M4JumperMakeStation.shape || shape != null) return null;
    switch (s) {
      case M4JumperMakeShape.tight:
        return _slip(M4JumperMakeMistakes.tightShape);
      case M4JumperMakeShape.long:
        return _slip(M4JumperMakeMistakes.longShape);
      case M4JumperMakeShape.smooth:
        shape = s;
        _tag(M4JumperMakeLines.caughtShape);
        return null;
    }
  }

  /// The stray strand trimmed ([byHand]: he found it himself).
  void trim({bool byHand = true}) {
    if (!stray) return;
    stray = false;
    if (byHand) _tag(M4JumperMakeLines.caughtEdge);
  }

  /// "কাজ শেষ": with a strand sticking out = a slip.
  DoMistake? finish() {
    if (station != M4JumperMakeStation.shape || shape == null || done) return null;
    if (stray) return _slip(M4JumperMakeMistakes.sharpEnd);
    done = true;
    return null;
  }

  /// On to the next station.
  void next() {
    stationSlips = 0;
    switch (station) {
      case M4JumperMakeStation.wire:
        station = M4JumperMakeStation.joint1;
      case M4JumperMakeStation.joint1:
        station = M4JumperMakeStation.joint2;
        brushed = false;
        pasted = false;
        conn = null;
        tight = false;
      case M4JumperMakeStation.joint2:
        station = M4JumperMakeStation.shape;
      case M4JumperMakeStation.shape:
        break;
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
///   wire: look at two pieces, take one ~4000 + reason ~8200           12200
///   each joint: brush 1400 + paste, connector ~2500 + tighten 1000
///     + reason ~8200 (× 2)                                            26200
///   the coworker: his line ~3500 + deck 910 + pick 3500               7900
///   shape: a bend, the strand, done ~3500 + reason ~8200              11700
///   ≈ 58000 ms; 85 % ≈ 49300 → 50 s.
const kM4JumperMakeQuickMs = 50000;

@immutable
class M4JumperMakePack {
  const M4JumperMakePack({required this.id, required this.titleBn, this.quickMs = kM4JumperMakeQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m4JumperMakePacks = {
  'do_4_2_a': M4JumperMakePack(id: 'do_4_2_a', titleBn: M4JumperMakeLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M4JumperMakePage extends StatefulWidget {
  const M4JumperMakePage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M4JumperMakePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4JumperMakePage> createState() => _M4JumperMakePageState();
}

class _M4JumperMakePageState extends State<M4JumperMakePage> {
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
  final M4JumperMakePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_JumperRunPage> createState() => _JumperRunPageState();
}

class _JumperRunPageState extends ConsumerState<_JumperRunPage>
    with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4JumperMakeRun _run = M4JumperMakeRun(m4JumperMakeDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// Brushing the faces (held; it keeps what was done when let go).
  late final AnimationController _brush = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _brushDone();
    });

  /// Tightening with two spanners (held).
  late final AnimationController _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _turnDone();
    });

  /// The jumper swinging in the wind after a wrong bend (one shot).
  late final AnimationController _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _busy = false;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  var _stamp = false;
  var _coworkerArmed = false;
  var _finishing = false;
  var _brushing = false;
  var _turning = false;

  /// Which spanner button the turn belongs to (one spanner: a slip when its
  /// hold fills), and where the finger went down.
  var _turnOne = false;
  Offset? _turnAt;

  /// The piece on the compare panel (station ক).
  int? _look;

  /// A wrong bend being shown (swinging) before its card.
  M4JumperMakeShape? _tryShape;
  var _spark = false;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hint (how to touch, never what) and its anchors.
  final _hints = IdleHintController();
  final _hintKeys = <String, GlobalKey>{};
  GlobalKey _hk(String id) => _hintKeys.putIfAbsent(id, GlobalKey.new);

  /// The joint rows left to right, as dealt.
  List<String> get _toolIds => _run.deal.brushFirst ? const ['brush', 'paste'] : const ['paste', 'brush'];
  List<String> get _wrenchIds => _run.deal.twoWrenchFirst ? const ['two-wrench', 'one-wrench'] : const ['one-wrench', 'two-wrench'];

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _brush.dispose();
    _turn.dispose();
    _sway.dispose();
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

  String get _task => M4JumperMakeLines.ask(_run.station, fitted: _run.conn != null, shaped: _run.shape != null);

  void _start() {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  /// Hands on the scene: no intro, card, deck or coworker, and not in a right
  /// move's praise window ([tableBusy]: a second tap there pays or slips
  /// nothing).
  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !tableBusy && !coworkerOpen && !struckOut;

  Offset get _handsAt {
    final size = MediaQuery.sizeOf(context);
    return Offset(size.width * 0.3, size.height * 0.78);
  }

  void _plainTap() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
  }

  /// A tap on the open scene (nothing there to work on).
  void _sceneTap() {
    if (!_canPlay) return;
    _hints.missTap();
    _plainTap();
  }

  /// The gesture hint for the waiting state: a sweep over every choice on
  /// screen (the order of the joint's steps and the right one stay unsaid).
  HintSpec? _hint() {
    final r = _run;
    switch (r.station) {
      case M4JumperMakeStation.wire:
        if (r.wire != null) return null;
        if (_look != null) return HintSpec.sweepOver([_hk('put-back'), _hk('take')]);
        return HintSpec.sweepOver([for (var i = 0; i < r.deal.pieces.length; i++) _hk('piece-$i')]);
      case M4JumperMakeStation.joint1:
      case M4JumperMakeStation.joint2:
        if (r.tight) return null;
        // In screen order (the rows are shuffled per play).
        if (r.conn == null) {
          return HintSpec.sweepOver([for (final id in _toolIds) _hk(id), for (final c in r.tray) _hk('conn-${c.name}')]);
        }
        return HintSpec.sweepOver([for (final id in _wrenchIds) _hk(id)]);
      case M4JumperMakeStation.shape:
        if (r.done) return null;
        if (r.shape == null) return HintSpec.sweepOver([for (final s in r.deal.shapes) _hk('shape-${s.name}')]);
        // The lens (with or without a strand) and done: never the strand itself.
        return HintSpec.sweepOver([_hk('lens'), _hk('finish')]);
    }
  }

  /// A new waiting state (a step done, a slip) resets the hint's count.
  String get _hintState {
    final r = _run;
    return '${r.station.name}-${r.wire}-$_look-${r.brushed}-${r.pasted}-${r.conn}-${r.tight}-${r.shape}-${r.stray}-${r.slips}';
  }

  // --- ক the wire ----------------------------------------------------------------
  void _lookAt(int i) {
    if (!_canPlay || _run.station != M4JumperMakeStation.wire) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.wav', volume: 0.45);
    setState(() => _look = _look == i ? null : i);
  }

  void _putBack() {
    if (!_canPlay) return;
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    setState(() => _look = null);
  }

  void _take(Offset origin) {
    final i = _look;
    if (!_canPlay || i == null || _run.wire != null) return;
    final m = _run.takePiece(i);
    if (m != null) {
      setState(() => _look = null);
      unawaited(_slipOut(m, origin));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.6);
    setState(() => _wake++);
    _stationRight(origin);
  }

  // --- খ গ the joints ------------------------------------------------------------
  void _brushDown() {
    if (!_canPlay || !_run.atJoint) return;
    // He pushes "no brush" at the right joint: he comes before the brush.
    if (holdForCoworker()) return;
    if (_run.brushed || _run.conn != null) {
      _plainTap();
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() => _brushing = true);
    unawaited(_brush.forward());
  }

  void _brushUp() {
    if (!_brushing) return;
    _brush.stop();
    setState(() => _brushing = false);
  }

  void _brushDone() {
    if (!mounted || _ended) return;
    _run.brushDone();
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.45);
    setState(() {
      _brushing = false;
      _wake++;
    });
  }

  void _paste(Offset origin) {
    if (!_canPlay || !_run.atJoint) return;
    if (holdForCoworker()) return;
    if (_run.pasted || _run.conn != null) {
      _plainTap();
      return;
    }
    final m = _run.paste();
    if (m != null) {
      unawaited(_slipOut(m, origin));
      return;
    }
    HapticFeedback.lightImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    setState(() => _wake++);
  }

  void _fit(M4JumperMakeConn c, Offset origin) {
    if (!_canPlay || !_run.atJoint || _run.conn != null) return;
    if (holdForCoworker()) return;
    final m = _run.fit(c);
    if (m != null) {
      unawaited(_slipOut(m, origin));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.8);
    _turn.value = 0;
    setState(() => _wake++);
    unawaited(_sayChain([M4JumperMakeLines.askTight]));
  }

  /// Both spanner buttons are held the same way; holding the one-spanner
  /// button until it fills is the slip.
  void _turnDown(Offset at, {required bool one}) {
    if (!_canPlay || _run.conn == null || _run.tight || _turning) return;
    HapticFeedback.selectionClick();
    // A switch of button starts the turn over.
    if (one != _turnOne) _turn.value = 0;
    setState(() {
      _turning = true;
      _turnOne = one;
      _turnAt = at;
    });
    unawaited(_turn.forward());
  }

  void _turnUp() {
    if (!_turning) return;
    _turn.stop();
    setState(() => _turning = false);
  }

  void _turnDone() {
    if (!mounted || _ended) return;
    if (_turnOne) {
      // One spanner: the bolt turns with the nut. Back to loose, and the slip.
      _turn.value = 0;
      setState(() {
        _turning = false;
        _wake++;
      });
      final m = _run.oneWrench();
      if (m != null) unawaited(_slipOut(m, _turnAt ?? _handsAt));
      return;
    }
    final done = _run.tighten();
    setState(() {
      _turning = false;
      _wake++;
    });
    if (!done) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/click.ogg', volume: 0.9);
    _stationRight(_handsAt);
  }

  // --- ঘ the shape ------------------------------------------------------------------
  Future<void> _bend(M4JumperMakeShape s, Offset origin) async {
    if (!_canPlay || _run.station != M4JumperMakeStation.shape || _run.shape != null) return;
    final m = _run.bend(s);
    HapticFeedback.selectionClick();
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.6);
      setState(() => _wake++);
      unawaited(_sayChain([M4JumperMakeLines.askFinish]));
      return;
    }
    // Show the wrong bend in the wind first, then the card.
    _busy = true;
    setState(() {
      _tryShape = s;
      _wake++;
    });
    if (_quiet) {
      _sway.value = 1;
    } else {
      await _sway.forward(from: 0);
    }
    if (!mounted) return;
    if (s == M4JumperMakeShape.long) {
      _cue('sounds/intro/impact_metal.ogg', volume: 0.7);
      setState(() => _spark = true);
    }
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 100 : 500));
    if (!mounted) return;
    _busy = false;
    await _slipOut(m, origin);
  }

  void _trim() {
    if (!_canPlay || _run.station != M4JumperMakeStation.shape || _run.shape == null) return;
    if (!_run.stray) {
      _plainTap();
      return;
    }
    _run.trim();
    HapticFeedback.lightImpact();
    _cue('sounds/intro/click.ogg', volume: 0.6);
    setState(() => _wake++);
  }

  Future<void> _finishJob(Offset origin) async {
    if (!_canPlay || _run.station != M4JumperMakeStation.shape || _run.shape == null || _run.done) return;
    final m = _run.finish();
    if (m != null) {
      await _slipOut(m, origin);
      return;
    }
    _hush();
    setState(() => _stamp = true);
    _stationRight(origin);
  }

  // --- a station done right: the ◆ and the reason ---------------------------------
  void _stationRight(Offset origin) {
    _hush();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    final station = _run.station;
    final copper = _run.copperJoint;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(askReason(
      deal: () => dealChoices(M4JumperMakeLines.whyRight(station, copper: copper), M4JumperMakeLines.excuses, widget.rng),
      question: M4JumperMakeLines.why(station),
      stillValid: () => _run.station == station && !_ended,
    ));
  }

  void _nextStation() {
    if (_run.station == M4JumperMakeStation.shape) {
      unawaited(_finish());
      return;
    }
    _run.next();
    _brush.value = 0;
    _turn.value = 0;
    setState(() {
      _look = null;
      _wake++;
    });
    _cue('sounds/learn/tag_slap.wav', volume: 0.4);
    unawaited(_sayChain([_task]));
    if (_run.station == M4JumperMakeStation.joint2 && !_coworkerArmed) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
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
    final st = _run.station;
    unawaited(Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
      if (mounted && !_ended && _run.station == st) _nextStation();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4JumperMakeLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.station.index > M4JumperMakeStation.joint2.index) return null;
    // "No brush, just put it on" fits only before the right joint's brush.
    if (_run.station == M4JumperMakeStation.joint2 && (_run.brushed || _run.conn != null || _brushing || _brush.value > 0)) return null;
    if (_run.station != M4JumperMakeStation.joint2) return false;
    if (_intro || _busy || _card != null || tableBusy || struckOut) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      await _slipOut(_run.listenNoBrush(), origin);
      return;
    }
    if (!_run.caught.contains(M4JumperMakeLines.caughtCall)) _run.caught.add(M4JumperMakeLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (mounted && !_ended) unawaited(_sayChain([_task]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M4JumperMakeLines.tapWhy[_nudgeN++ % M4JumperMakeLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _slipOut(DoMistake m, Offset origin) async {
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

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
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('jumper/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    // Done with the strand out: it is trimmed now (he has seen it).
    if (_card == M4JumperMakeMistakes.sharpEnd) _run.trim(byHand: false);
    _sway.value = 0;
    setState(() {
      _card = null;
      _tryShape = null;
      _spark = false;
      _wake++;
    });
    unawaited(_sayChain([_task]));
  }

  Future<void> _levelDelta(int delta, Offset origin, {GuideMood? mood}) async {
    final next = math.max(0, _runScore + delta);
    final real = next - _runScore;
    if (real == 0 || !mounted) return;
    setState(() => _runScore = next);
    await BeatFx.levelDelta(ref, real, mood: mood, originGlobal: origin, muted: _muted);
  }

  Future<void> _finish() async {
    // Once only: a second call (while the first awaits the save) must not
    // record, pay or commit again.
    if (_finishing || (_ended && !_run.done) || _mark != null) return;
    _finishing = true;
    _ended = true;
    _clock.stop();
    setState(() => _wake++);
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
    await _say(!_run.passed ? M4JumperMakeLines.fail : (_quickBonus ? M4JumperMakeLines.quick : M4JumperMakeLines.allSet),
        mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
  }

  void _popOnce(bool cleared) {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(cleared);
  }

  Future<void> _leave() async {
    if (_passed) {
      _popOnce(true);
      return;
    }
    final leave = await showGameExitSheet(context, scope: GameExitScope.level, bn: true);
    if (leave == true) _popOnce(false);
  }

  // --- the scene ---------------------------------------------------------------
  LinemanMode get _mode {
    if (_card != null) return LinemanMode.worried;
    if (coworkerOpen) return LinemanMode.worried;
    if (_mark != null && _passed) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  M4JumperMakeRig get _rig {
    final st = _run.station;
    final leftOn = st.index > M4JumperMakeStation.joint1.index || (st == M4JumperMakeStation.joint1 && _run.tight);
    final rightOn = st.index > M4JumperMakeStation.joint2.index || (st == M4JumperMakeStation.joint2 && _run.tight);
    return M4JumperMakeRig(copperRight: _run.deal.copperRight, leftOn: leftOn, rightOn: rightOn, shape: _tryShape ?? _run.shape);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = M4JumperMakeGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final tb = geo.traineeBox;
    final rig = _rig;
    return [
      Positioned.fill(
        key: const ValueKey('land'),
        child: RepaintBoundary(child: CustomPaint(painter: M4JumperMakeWorldPainter(geo: geo, rig: rig))),
      ),
      Positioned.fill(
        key: const ValueKey('strap'),
        child: IgnorePointer(child: CustomPaint(painter: M4JumperMakeStrapPainter(box: tb))),
      ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: tb,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      Positioned.fill(
        key: const ValueKey('jumper'),
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: M4JumperMakeJumperPainter(geo: geo, rig: rig, sway: _sway, spark: _spark)),
          ),
        ),
      ),
      if (_stamp)
        Positioned(
          key: const ValueKey('stamp'),
          left: M4JumperMakeGeo.px - 70,
          top: geo.lineY - 76,
          child: IgnorePointer(child: _StampPop(text: M4JumperMakeLines.stampDone, quiet: quiet)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4JumperMakeLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _sceneTap),
        ),
      ),
    ];
  }

  M4JumperMakeJointView get _jointView {
    final r = _run;
    if (r.station == M4JumperMakeStation.shape) {
      return M4JumperMakeJointView(brushed: 1, pasted: true, conn: M4JumperMakeConn.pgAl, tight: 1, stray: r.stray);
    }
    return M4JumperMakeJointView(
      copper: r.copperJoint,
      brushed: r.brushed ? 1 : _brush.value,
      pasted: r.pasted,
      conn: r.conn,
      tight: r.tight ? 1 : _turn.value,
      wrenches: _turning ? (_turnOne ? 1 : 2) : 0,
    );
  }

  List<Widget> _hud(EdgeInsets pad, bool quiet) {
    final r = _run;
    final st = r.station;
    final w = MediaQuery.sizeOf(context).width;
    switch (st) {
      case M4JumperMakeStation.wire:
        if (r.wire != null) return const [];
        return [
          if (_look != null)
            Positioned(
              key: ValueKey('hud-compare-$_look'),
              left: 12,
              right: 12,
              bottom: pad.bottom + 128,
              child: _ComparePanel(
                piece: r.deal.pieces[_look!],
                acsr: r.deal.acsr,
                onTake: _take,
                onBack: _putBack,
                takeKey: _hk('take'),
                backKey: _hk('put-back'),
              ),
            ),
          Positioned(
            key: const ValueKey('hud-rack'),
            left: 8,
            right: 8,
            bottom: pad.bottom + 12,
            child: Row(
              children: [
                for (var i = 0; i < r.deal.pieces.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: KeyedSubtree(
                        key: _hk('piece-$i'),
                        child: _CoilTile(
                          key: ValueKey('piece-$i'),
                          label: M4JumperMakeLines.piece(i),
                          tag: M4JumperMakeLines.material(r.deal.acsr),
                          piece: r.deal.pieces[i],
                          acsr: r.deal.acsr,
                          selected: _look == i,
                          onTap: () => _lookAt(i),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ];
      case M4JumperMakeStation.joint1:
      case M4JumperMakeStation.joint2:
        if (r.tight) return [_lens(pad, w)];
        final n = r.tray.length;
        final chipW = (w - 16 - 6 * (n - 1)) / n;
        return [
          _lens(pad, w),
          if (r.conn == null)
            Positioned(
              key: ValueKey('hud-tray-${st.name}'),
              left: 8,
              right: 8,
              bottom: pad.bottom + 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The brush (held) and the paste (a tap) look alike, in
                  // the dealt order: the row never reads out the steps.
                  Row(
                    children: [
                      for (final (i, id) in _toolIds.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: id == 'brush'
                              ? _HoldButton(
                                  key: _hk('brush'),
                                  label: M4JumperMakeLines.brush,
                                  progress: _brush,
                                  done: r.brushed,
                                  onDown: (_) => _brushDown(),
                                  onUp: _brushUp,
                                )
                              : _TapChip(
                                  key: _hk('paste'),
                                  label: M4JumperMakeLines.paste,
                                  done: r.pasted,
                                  onTapUp: (d) => _paste(d.globalPosition),
                                ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final (i, c) in r.tray.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        SizedBox(
                          width: chipW,
                          child: _ConnChip(key: _hk('conn-${c.name}'), conn: c, onTapUp: (d) => _fit(c, d.globalPosition)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
          else
            Positioned(
              key: ValueKey('hud-tighten-${st.name}'),
              left: 12,
              right: 12,
              bottom: pad.bottom + 12,
              // Two look-alike hold buttons in the dealt order; the one-spanner
              // hold fills too, then slips.
              child: Row(
                children: [
                  for (final (i, id) in _wrenchIds.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _HoldButton(
                        key: _hk(id),
                        label: id == 'one-wrench' ? M4JumperMakeLines.oneWrench : M4JumperMakeLines.twoWrench,
                        progress: _turnOne == (id == 'one-wrench') ? _turn : kAlwaysDismissedAnimation,
                        done: false,
                        onDown: (at) => _turnDown(at, one: id == 'one-wrench'),
                        onUp: _turnUp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ];
      case M4JumperMakeStation.shape:
        if (r.done) return const [];
        if (r.shape == null) {
          return [
            Positioned(
              key: const ValueKey('hud-shapes'),
              left: 8,
              right: 8,
              bottom: pad.bottom + 12,
              child: Row(
                children: [
                  for (final (i, s) in r.deal.shapes.indexed) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: KeyedSubtree(
                        key: _hk('shape-${s.name}'),
                        child: _ShapeTile(
                          key: ValueKey('shape-${s.name}'),
                          shape: s,
                          selected: _tryShape == s,
                          onTapUp: (d) => unawaited(_bend(s, d.globalPosition)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ];
        }
        return [
          _lens(pad, w, below: 72),
          Positioned(
            key: const ValueKey('hud-finish'),
            left: 12,
            right: 12,
            bottom: pad.bottom + 12,
            child: DoBigButton(key: _hk('finish'), label: M4JumperMakeLines.finish, filled: true, onTapUp: (d) => unawaited(_finishJob(d.globalPosition))),
          ),
        ];
    }
  }

  Widget _lens(EdgeInsets pad, double w, {double below = 128}) {
    final view = _jointView;
    final lensW = math.min(240.0, w - 140);
    return Positioned(
      key: ValueKey('hud-lens-${_run.station.name}'),
      left: 12,
      bottom: pad.bottom + below,
      width: lensW,
      height: lensW * 0.58,
      child: _Lens(
        key: _hk('lens'),
        view: view,
        brushing: _brushing ? _brush : null,
        turning: _turning ? _turn : null,
        onStrand: _run.station == M4JumperMakeStation.shape ? _trim : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended;
    final hintWaiting = handsOn && !_busy && !_ended && !tableBusy && !coworkerOnScreen && !_brushing && !_turning;
    final st = _run.station;
    final guideBottom = deckUp
        ? 236.0
        : !handsOn
            ? 72.0
            : switch (st) {
                M4JumperMakeStation.wire => _look != null ? 300.0 : 130.0,
                M4JumperMakeStation.joint1 || M4JumperMakeStation.joint2 => 132.0,
                M4JumperMakeStation.shape => _run.shape == null ? 130.0 : 76.0,
              };
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
              labels: M4JumperMakeLines.rounds,
              done: {for (var i = 0; i < st.index; i++) i, if (_run.done) 3},
              current: _run.done ? null : st.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: hintWaiting,
            hintKey: _hintState,
            hintController: _hints,
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(acsr: _run.deal.acsr, copper: _run.deal.copperRight)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn) ..._hud(pad, quiet),
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
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + guideBottom, onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${st.name}'),
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
                  line: M4JumperMakeLines.intro,
                  alarm: null,
                  muted: _muted,
                  onDone: () {
                    setState(() => _intro = false);
                    _start();
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

const _panelFill = Color(0xE60B1324);

BoxDecoration _panel({Color ring = const Color(0x55FFFFFF), double width = 1.2}) => BoxDecoration(
      color: _panelFill,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ring, width: width),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
    );

/// The docket: the job, the line's conductor and that the line is dead.
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.acsr, required this.copper});
  final bool acsr;
  final bool copper;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(M4JumperMakeLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M4JumperMakeLines.job, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text(M4JumperMakeLines.line(acsr), style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF2B2416))),
          if (copper)
            Text(M4JumperMakeLines.copperSide, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF8E4F23))),
          Text(M4JumperMakeLines.permit, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E6B3A))),
        ],
      ),
    );
  }
}

/// A coil on the rack: tap to look at its cut end beside the line's.
class _CoilTile extends StatelessWidget {
  const _CoilTile({super.key, required this.label, required this.tag, required this.piece, required this.acsr, required this.selected, required this.onTap});
  final String label;
  final String tag;
  final double piece;
  final bool acsr;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 100,
          decoration: _panel(ring: selected ? SlmColors.gold300 : const Color(0x55FFFFFF), width: selected ? 2.4 : 1.2),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: CustomPaint(painter: M4JumperMakeCoilPainter(piece: piece, steelCore: acsr), size: Size.infinite),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(tag, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two cut ends side by side, and take / put back.
class _ComparePanel extends StatelessWidget {
  const _ComparePanel({required this.piece, required this.acsr, required this.onTake, required this.onBack, this.takeKey, this.backKey});
  final double piece;
  final bool acsr;
  final void Function(Offset) onTake;
  final VoidCallback onBack;
  final Key? takeKey;
  final Key? backKey;

  @override
  Widget build(BuildContext context) {
    final cap = bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ivory);
    return Container(
      decoration: _panel(),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 92,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFE9E3D2), borderRadius: BorderRadius.circular(10)),
              child: CustomPaint(painter: M4JumperMakeCrossPainter(piece: piece, steelCore: acsr), size: Size.infinite),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(M4JumperMakeLines.lineWire, textAlign: TextAlign.center, style: cap)),
              Expanded(child: Text(M4JumperMakeLines.thisPiece, textAlign: TextAlign.center, style: cap)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: DoBigButton(key: backKey, label: M4JumperMakeLines.putBack, filled: false, onDark: true, onTapUp: (_) => onBack())),
              const SizedBox(width: 10),
              Expanded(child: DoBigButton(key: takeKey, label: M4JumperMakeLines.take, filled: true, onTapUp: (d) => onTake(d.globalPosition))),
            ],
          ),
        ],
      ),
    );
  }
}

/// The joint close up (and, at the end, the strand to trim).
class _Lens extends StatelessWidget {
  const _Lens({super.key, required this.view, this.brushing, this.turning, this.onStrand});
  final M4JumperMakeJointView view;
  final Animation<double>? brushing;
  final Animation<double>? turning;
  final VoidCallback? onStrand;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panel(ring: const Color(0x99FFFFFF), width: 2),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(builder: (context, box) {
        final s = Size(box.maxWidth, box.maxHeight);
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: M4JumperMakeJointPainter(view: view, brushing: brushing, turning: turning)),
              ),
            ),
            if (onStrand != null)
              Positioned.fromRect(
                rect: M4JumperMakeJointPainter.strandArea(s),
                child: Semantics(
                  button: true,
                  label: M4JumperMakeLines.strand,
                  excludeSemantics: true,
                  child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onStrand),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// A connector on the tray.
class _ConnChip extends StatelessWidget {
  const _ConnChip({super.key, required this.conn, required this.onTapUp});
  final M4JumperMakeConn conn;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final label = M4JumperMakeLines.conn(conn);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          height: 64,
          decoration: _panel(),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Column(
            children: [
              Expanded(child: CustomPaint(painter: M4JumperMakeConnPainter(conn: conn), size: Size.infinite)),
              FittedBox(child: Text(label, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.ivory))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bend on the shape tiles (a picture only).
class _ShapeTile extends StatelessWidget {
  const _ShapeTile({super.key, required this.shape, required this.selected, required this.onTapUp});
  final M4JumperMakeShape shape;
  final bool selected;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: M4JumperMakeLines.shape(shape),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          height: 112,
          decoration: _panel(ring: selected ? SlmColors.gold300 : const Color(0x55FFFFFF), width: selected ? 2.4 : 1.2),
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(color: const Color(0xFFBFD8EC), borderRadius: BorderRadius.circular(9)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CustomPaint(painter: M4JumperMakeShapePainter(shape: shape), size: Size.infinite),
            ),
          ),
        ),
      ),
    );
  }
}

/// A one-tap tool (the paste).
class _TapChip extends StatelessWidget {
  const _TapChip({super.key, required this.label, required this.done, required this.onTapUp});
  final String label;
  final bool done;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: Container(
          height: 52,
          decoration: _toolPanel(done),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _ToolFace(label: label, done: done),
        ),
      ),
    );
  }
}

/// Hold to work (brushing, tightening): it fills while held. At rest it looks
/// just like a [_TapChip] (the same panel and label), so no tool or spanner
/// stands out as the main action.
class _HoldButton extends StatelessWidget {
  const _HoldButton({super.key, required this.label, required this.progress, required this.done, required this.onDown, required this.onUp});
  final String label;
  final Animation<double> progress;
  final bool done;
  final ValueChanged<Offset> onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (e) => onDown(e.position),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Container(
          height: 52,
          decoration: _toolPanel(done),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!done)
                  AnimatedBuilder(
                    animation: progress,
                    builder: (_, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.value.clamp(0.0, 1.0),
                      child: const ColoredBox(color: Color(0x44FFFFFF)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _ToolFace(label: label, done: done),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shared look of the joint's tool buttons (hold or tap).
BoxDecoration _toolPanel(bool done) => _panel(ring: done ? SlmColors.success : const Color(0x99FFFFFF), width: 1.6);

class _ToolFace extends StatelessWidget {
  const _ToolFace({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check_circle_rounded, size: 20, color: SlmColors.success),
            const SizedBox(width: 6),
          ],
          Text(label, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ],
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
