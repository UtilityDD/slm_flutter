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
import 'm3_service_drop_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm3_service_drop_world.dart' show M3ServiceDropDrum, M3ServiceDropEntry, M3ServiceDropGeo, M3ServiceDropSpot;

// Lesson 3.8 "সার্ভিস কেবিল ও এনার্জি মিটার: শেষ সংযোগ", কাজ 1 "শেষ মাইল"
// (pack do_3_8_a, engine m3_service_drop). A new service connection: run the
// service drop from the LT pole to the house's meter box. The LT line is
// under shutdown, PTW and earth (the docket says so; the earth set is drawn
// on the pole). Three stations a play:
//   ক cable — the docket says single-phase or three-phase (dealt): take the
//     weather-proof Al cable with the right cores (twin-core = phase +
//     neutral; four-core = R, Y, B + neutral — point 1's specification), and
//     not the drum whose insulation is cut (point 1's daily check);
//   খ bearer — the order (point 1's installation, pro tip 2): first the GI
//     bearer wire from the pole's service bracket to the wall hook, then the
//     cable along it, then the clips — the bearer takes all the tension, the
//     cable none; the careless coworker pushes "no bearer, tie the cable
//     taut" (he comes as the station starts; the first tool laid on the span
//     waits for him — holdForCoworker — and once a bearer or the cable is up
//     his push no longer fits, so he does not come). The tool bag is dealt in
//     a shuffled order, never the lesson's order;
//   গ loop — pro tip 1: before the meter box the cable makes a U drip loop
//     and comes up into the box from below (not straight in from the top or
//     the side: rain runs down the cable into the meter).
//
// Slips only (no deadly move): a drum with the wrong cores, a drum with cut
// insulation, the cable before the bearer, the clips before the cable (a
// wrong-order probe is never free), listening to him, no drip loop.
// Three slips strike the level out.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m3_service_drop_world.dart), corner guide, ◆ on the table →
// "কেন …?" → the next station by itself; the coworker once a play.
// Kit (2026-11-11): no scene control works in a praise window (`tableBusy`
// in `_canPlay`, and he never comes then); gesture hints (how, never what):
// a sweep over the drums / the tools / the three ways into the meter box, a
// tap only on the single way forward (the last tool, then the span); taps on
// nothing call the hand. A won station's control never fires again
// (`_stationWon` in `_canPlay`). Each reason deck deals one station-specific
// wrong reason beside the excuse, so the station's own subject is never on
// the right card alone (a deck may still show one word, e.g. ইনসুলেশন, only
// on the right card).
// Voice: the guide's lines by device TTS; the coworker's push is silent with
// its caption held until it is recorded in his voice (his exit line is
// already recorded).

// ============================================================================
// Content
// ============================================================================

enum M3ServiceDropStation { cable, bearer, loop }

enum M3ServiceDropTool { bearer, cable, clip }

abstract final class M3ServiceDropLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [askCable, askBearer, askClip, askLoop];

  static const title = 'শেষ মাইল';
  static const intro = 'নতুন কানেকশন! পোল থেকে বাড়ির মিটার পর্যন্ত সার্ভিস কেবিল টানুন।';
  static const rounds = ['ক', 'খ', 'গ'];

  static const askCable = 'ডকেট দেখে ঠিক কেবিলটা বেছে নিন।';
  static const askBearer = 'পোল থেকে বাড়ি পর্যন্ত কেবিল ঝোলান।';
  static const askClip = 'এবার কেবিলে ক্লিপ লাগান।';
  static const askLoop = 'এবার কেবিলটা মিটার বক্সে ঢোকান।';
  static String ask(M3ServiceDropStation s, {bool laid = false}) => switch (s) {
        M3ServiceDropStation.cable => askCable,
        M3ServiceDropStation.bearer => laid ? askClip : askBearer,
        M3ServiceDropStation.loop => askLoop,
      };
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads.
  static const sceneLabel = 'পোল থেকে বাড়ি';
  static const twin = 'টুইন-কোর';
  static const four = 'ফোর-কোর';
  static const bearer = 'বিয়ারার তার';
  static const cable = 'কেবিল';
  static const clip = 'ক্লিপ';
  static const docket = 'ডকেট';
  static const job = 'নতুন সার্ভিস কানেকশন';
  static const single = 'সিঙ্গেল-ফেজ';
  static const three = 'থ্রি-ফেজ';
  static const permit = 'শাটডাউন · PTW · আর্থ';

  // The reasons (lesson 3.8): the right ones state this station's rule (and
  // fit the cable he actually took); the wrong ones are field excuses.
  static const whyCable = 'কেন এই কেবিলটা নিলেন?';
  static const whyBearer = 'কেবিল এভাবে কেন ঝোলালেন?';
  static const whyLoop = 'মিটারের আগে এই বাঁক কেন?';
  static String why(M3ServiceDropStation s) => switch (s) {
        M3ServiceDropStation.cable => whyCable,
        M3ServiceDropStation.bearer => whyBearer,
        M3ServiceDropStation.loop => whyLoop,
      };

  static const cableWhySingle = [
    'সিঙ্গেল-ফেজে ফেজ আর নিউট্রাল, তাই টুইন-কোর',
    'এক ফেজের কানেকশনে টুইন-কোর কেবিলই লাগে',
    'ইনসুলেশন অক্ষত, কোথাও কাটা-ছেঁড়া নেই',
  ];
  static const cableWhyThree = [
    'থ্রি-ফেজে R, Y, B আর নিউট্রাল — তাই ফোর-কোর',
    'তিন ফেজের কানেকশনে ফোর-কোর কেবিলই লাগে',
    'ইনসুলেশন অক্ষত, কোথাও কাটা-ছেঁড়া নেই',
  ];
  static const bearerWhy = [
    'সব টান বিয়ারার তার নেবে, কেবিলে কোনো টান নয়',
    'কেবিলের ওপর টান পড়লে সেটা ছিঁড়ে যেতে পারে',
    'আগে বিয়ারার, তারপর ক্লিপে কেবিল — এই নিয়ম',
  ];
  static const loopWhy = [
    'U লুপে জল নিচে ঝরে যায়, মিটারে ঢোকে না',
    'বৃষ্টির জল কেবিল বেয়ে মিটারে ঢুকতে পারবে না',
    'ড্রিপ লুপ বৃষ্টির জলকে মিটার থেকে দূরে রাখে',
  ];
  static List<String> whyRight(M3ServiceDropStation s, {bool three = false}) => switch (s) {
        M3ServiceDropStation.cable => three ? cableWhyThree : cableWhySingle,
        M3ServiceDropStation.bearer => bearerWhy,
        M3ServiceDropStation.loop => loopWhy,
      };

  // Station-specific wrong reasons (field myths in the station's own words,
  // so "কোর" / "বিয়ারার" / "লুপ" never appear on the right card alone).
  static const cableWrongSingle = [
    'ফোর-কোর নিলেই ভালো, পরে কাজে লাগতে পারে',
    'যে কোরের কেবিলই হোক, বাতি তো জ্বলবেই',
    'ইনসুলেশনে একটু কাটা থাকলেও কিছু হয় না',
  ];
  static const cableWrongThree = [
    'টুইন-কোরেই তিন ফেজ চলে, কোর কম হলেও চলে',
    'যে কোরের কেবিলই হোক, বাতি তো জ্বলবেই',
    'ইনসুলেশনে একটু কাটা থাকলেও কিছু হয় না',
  ];
  static const bearerWrong = [
    'কেবিল টানটান থাকলে বিয়ারার না দিলেও চলে',
    'বিয়ারার শুধু দেখানোর জন্য, টান কেবিলই নেয়',
    'ক্লিপ আর বিয়ারার তো কেবিল সাজানোর জিনিস',
  ];
  static const loopWrong = [
    'ড্রিপ লুপ শুধু দেখতে সুন্দর লাগে বলে দিলাম',
    'মিটার বক্স তো ঢাকা, জল ঢোকার কোনো ভয় নেই',
    'কেবিল বেশি লম্বা ছিল, তাই বাঁক দিয়ে রাখলাম',
  ];
  static List<String> whyWrong(M3ServiceDropStation s, {bool three = false}) => switch (s) {
        M3ServiceDropStation.cable => three ? cableWrongThree : cableWrongSingle,
        M3ServiceDropStation.bearer => bearerWrong,
        M3ServiceDropStation.loop => loopWrong,
      };

  /// The reason deck: one right, one station-specific wrong, and one more
  /// wrong from the rest (station-specific or a field excuse).
  static List<ChoiceOption> dealWhy(M3ServiceDropStation s, math.Random rng, {bool three = false}) {
    final own = [...whyWrong(s, three: three)]..shuffle(rng);
    final rest = [...own.skip(1), ...excuses];
    return dealChoices(whyRight(s, three: three), [own.first, rest[rng.nextInt(rest.length)]], rng);
  }

  /// Field excuses (wrong on every deck; one is the lesson's neutral myth).
  static const excuses = [
    'তাড়াতাড়ি শেষ হবে, তাই এভাবেই করলাম',
    'সবাই তো এভাবেই করে, কিছু হয় না কখনো',
    'দেখতে ভালো লাগে, তাই এভাবেই করে দিলাম',
    'সুপারভাইজার দেখছেন না, এতেই চলে যাবে',
    'নিউট্রালে কারেন্ট নেই, তাই কোনো চিন্তা নেই',
    'গ্রাহক তাড়া দিচ্ছেন, তাই এভাবেই সারলাম',
  ];

  /// The careless coworker: no bearer, the cable tied taut (pro tip 2).
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'আরে! বিয়ারার লাগবে না, কেবিল টানটান করে বেঁধে দাও।',
    exitLine: coworkerExit,
    // No lead word ("না" / "ঠিক") marks a side: both sides speak of the
    // bearer, the cable and the pull.
    right: ['সব টান বিয়ারার তারই নেবে, ওটা আগে', 'কেবিলে টান পড়লে ছিঁড়ে যেতে পারে', 'আগে বিয়ারার, তারপর কেবিল ক্লিপে'],
    wrong: ['কেবিলটাই টানটান করে বেঁধে দিই', 'বিয়ারার ছাড়াই কেবিল ঝুলিয়ে দিই', 'কেবিল তো শক্ত, টানে ছিঁড়বে না', 'বিয়ারার পরে লাগালেও কিছু হবে না', 'ঝটপট হবে, বিয়ারারটা বাদ দিই'],
    asks: ['ও বলছে বিয়ারার লাগবে না। আপনি কী করবেন?', 'বিয়ারার দেবেন, না কেবিল টানটান বাঁধবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );

  static const allSet = 'শেষ মাইল ঠিকঠাক — ঠিক কেবিল, বিয়ারারে ঝোলানো, মিটারের আগে ড্রিপ লুপ।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — ডকেট দেখে কেবিল, আগে বিয়ারার, শেষে ড্রিপ লুপ।';

  // "আজ যা ধরলেন".
  static const caughtCore = 'ডকেট মিলিয়ে ঠিক কোরের কেবিল';
  static const caughtCut = 'কাটা ইনসুলেশনের কেবিল বাদ';
  static const caughtBearer = 'আগে বিয়ারার, কেবিল ক্লিপে';
  static const caughtLoop = 'মিটারের আগে U ড্রিপ লুপ';
  static const caughtCall = 'চাপে “না” — টান বিয়ারারে';
}

abstract final class M3ServiceDropMistakes {
  static const _dir = 'assets/game/art/m3_service_drop';

  static const wrongCore = DoMistake(
    key: '3.8/m3_service_drop/wrong-core',
    textBn: 'ডকেট মিলিয়ে কেবিল নিন: সিঙ্গেল-ফেজে টুইন-কোর (ফেজ + নিউট্রাল), থ্রি-ফেজে ফোর-কোর (R, Y, B + নিউট্রাল)।',
    art: '$_dir/core.svg',
    lessonPoint: 0,
  );
  static const cutInsulation = DoMistake(
    key: '3.8/m3_service_drop/cut-insulation',
    textBn: 'এই কেবিলের ইনসুলেশন কাটা — শর্ট সার্কিট বা লিকেজ কারেন্টের কারণ হয়। লাগানোর আগে দেখুন, কোথাও কাটা বা ক্ষতি নেই তো।',
    art: '$_dir/cut.svg',
    lessonPoint: 0,
  );
  static const noBearer = DoMistake(
    key: '3.8/m3_service_drop/cable-before-bearer',
    textBn: 'আগে জিআই বিয়ারার তার পোল থেকে বাড়ি পর্যন্ত টানুন, তারপর কেবিল তার সাথে ক্লিপে ঝোলান — কেবিলের নিজের ওপর যেন কোনো টান না পড়ে।',
    art: '$_dir/bearer.svg',
    lessonPoint: 0,
  );
  /// The clips before the cable is along the bearer (the order again).
  static const clipFirst = DoMistake(
    key: '3.8/m3_service_drop/clip-before-cable',
    textBn: 'ক্লিপ শেষে: আগে জিআই বিয়ারার তার, তারপর কেবিল তার পাশে পাশে, তারপর ক্লিপে কেবিল বিয়ারারে আটকান — টান নেবে বিয়ারার।',
    art: '$_dir/bearer.svg',
    lessonPoint: 0,
  );
  static const tautCable = DoMistake(
    key: '3.8/m3_service_drop/taut-cable',
    textBn: 'কেবিল টানটান করে বাঁধলে সব টান কেবিলের ওপর পড়ে — ছিঁড়ে যেতে পারে। সমস্ত টান নেবে বিয়ারার তার।',
    art: '$_dir/taut.svg',
    lessonPoint: 0,
  );

  /// Pro tip 1: the pro tips are not a lesson point, so "পাঠে দেখুন" opens
  /// the lesson from its start.
  static const noDripLoop = DoMistake(
    key: '3.8/m3_service_drop/no-drip-loop',
    textBn: 'মিটার বক্সে ঢোকানোর আগে কেবিলে একটা U আকারের ড্রিপ লুপ চাই — নইলে বৃষ্টির জল কেবিল বেয়ে মিটারের ভেতরে ঢোকে।',
    art: '$_dir/loop.svg',
  );

  static const all = [wrongCore, cutInsulation, noBearer, clipFirst, tautCable, noDripLoop];
}

/// One play: single- or three-phase, the three drums on the lane (one right,
/// one of the right cores with cut insulation, one of the wrong cores).
@immutable
class M3ServiceDropDeal {
  const M3ServiceDropDeal({required this.three, required this.drums, this.tools = const [M3ServiceDropTool.cable, M3ServiceDropTool.clip, M3ServiceDropTool.bearer]});

  /// The docket's connection is three-phase (else single-phase).
  final bool three;
  final List<M3ServiceDropDrum> drums;

  /// The tool bag's order on screen (never the lesson's order).
  final List<M3ServiceDropTool> tools;

  /// The lesson's order (bearer → cable → clips): the bag is never laid out so.
  static const lessonOrder = [M3ServiceDropTool.bearer, M3ServiceDropTool.cable, M3ServiceDropTool.clip];

  int get right => drums.indexWhere((d) => d.four == three && !d.cut);
  int get cut => drums.indexWhere((d) => d.cut);
  int get wrong => drums.indexWhere((d) => d.four != three);
}

M3ServiceDropDeal m3ServiceDropDeal(math.Random rng) {
  final three = rng.nextBool();
  final angle = -0.4 + rng.nextDouble() * 2.6;
  final drums = [
    M3ServiceDropDrum(four: three, cut: false),
    M3ServiceDropDrum(four: three, cut: true, cutAngle: angle),
    M3ServiceDropDrum(four: !three, cut: false),
  ]..shuffle(rng);
  final tools = [...M3ServiceDropDeal.lessonOrder];
  do {
    tools.shuffle(rng);
  } while (_sameOrder(tools, M3ServiceDropDeal.lessonOrder));
  return M3ServiceDropDeal(three: three, drums: drums, tools: tools);
}

bool _sameOrder(List<M3ServiceDropTool> a, List<M3ServiceDropTool> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The play state (pure logic).
class M3ServiceDropRun {
  M3ServiceDropRun(this.deal);
  final M3ServiceDropDeal deal;

  M3ServiceDropStation station = M3ServiceDropStation.cable;
  int slips = 0;
  final List<String> caught = [];

  /// Slips at the current station (a clean station pays +5).
  int stationSlips = 0;

  // cable
  int? taken;
  final Set<int> tried = {};

  // bearer
  bool bearer = false;
  bool cableOn = false;
  bool clipped = false;

  // loop
  M3ServiceDropEntry? entry;

  bool get done => entry == M3ServiceDropEntry.loop;
  bool get ended => done;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && percent >= 55;
  bool get clean => stationSlips == 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    stationSlips++;
    return m;
  }

  /// Take drum [i]: the wrong cores or cut insulation is a slip.
  DoMistake? takeDrum(int i) {
    if (station != M3ServiceDropStation.cable || taken != null) return null;
    tried.add(i);
    final d = deal.drums[i];
    if (d.four != deal.three) return _slip(M3ServiceDropMistakes.wrongCore);
    if (d.cut) return _slip(M3ServiceDropMistakes.cutInsulation);
    taken = i;
    _tag(M3ServiceDropLines.caughtCore);
    // He passed over the cut drum of the same cores.
    if (!tried.contains(deal.cut)) _tag(M3ServiceDropLines.caughtCut);
    return null;
  }

  /// The GI bearer from the pole's bracket to the wall hook.
  bool stringBearer() {
    if (station != M3ServiceDropStation.bearer || bearer) return false;
    bearer = true;
    return true;
  }

  /// The cable along the span: before the bearer it is a slip (not laid).
  DoMistake? layCable() {
    if (station != M3ServiceDropStation.bearer || cableOn) return null;
    if (!bearer) return _slip(M3ServiceDropMistakes.noBearer);
    cableOn = true;
    return null;
  }

  /// The clips: before the cable is along the bearer it is a slip (not
  /// hung); else the cable is hung ([clipped]).
  DoMistake? clip() {
    if (station != M3ServiceDropStation.bearer || clipped) return null;
    if (!cableOn) return _slip(M3ServiceDropMistakes.clipFirst);
    clipped = true;
    _tag(M3ServiceDropLines.caughtBearer);
    return null;
  }

  /// Listened to him: the cable tied taut, no bearer.
  DoMistake listenTaut() => _slip(M3ServiceDropMistakes.tautCable);

  /// How the cable goes into the meter box: only a U drip loop is right.
  DoMistake? route(M3ServiceDropEntry e) {
    if (station != M3ServiceDropStation.loop || done) return null;
    if (e != M3ServiceDropEntry.loop) return _slip(M3ServiceDropMistakes.noDripLoop);
    entry = e;
    _tag(M3ServiceDropLines.caughtLoop);
    return null;
  }

  /// On to the next station.
  void next() {
    stationSlips = 0;
    switch (station) {
      case M3ServiceDropStation.cable:
        station = M3ServiceDropStation.bearer;
      case M3ServiceDropStation.bearer:
        station = M3ServiceDropStation.loop;
      case M3ServiceDropStation.loop:
        break;
    }
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
///   cable: read the docket and the drums ~4000 + reason ~8200       12200
///   bearer: he comes ~1800 + his line ~3500 + deck 910 + pick 3500
///     + three tools, six taps ~6000 + reason ~8200                  23900
///   loop: one tap ~2500 + reason ~8200                              10700
///   ≈ 46800 ms; 85 % ≈ 39800 → 40 s.
const kM3ServiceDropQuickMs = 40000;

@immutable
class M3ServiceDropPack {
  const M3ServiceDropPack({required this.id, required this.titleBn, this.quickMs = kM3ServiceDropQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const m3ServiceDropPacks = {
  'do_3_8_a': M3ServiceDropPack(id: 'do_3_8_a', titleBn: M3ServiceDropLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M3ServiceDropPage extends StatefulWidget {
  const M3ServiceDropPage({super.key, required this.ctx, required this.pack, required this.muted, this.seed});

  final LevelContext ctx;
  final M3ServiceDropPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M3ServiceDropPage> createState() => _M3ServiceDropPageState();
}

class _M3ServiceDropPageState extends State<M3ServiceDropPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DropRunPage(
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

class _DropRunPage extends ConsumerStatefulWidget {
  const _DropRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M3ServiceDropPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DropRunPage> createState() => _DropRunPageState();
}

class _DropRunPageState extends ConsumerState<_DropRunPage>
    with DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M3ServiceDropRun _run = M3ServiceDropRun(m3ServiceDropDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The trainee moving between his spots.
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  int _runScore = 0;
  var _intro = true;
  int _chain = 0;
  DoMistake? _card;
  var _ended = false;
  var _passed = false;
  var _popped = false;
  var _quickBonus = false;
  int _stars = 0;
  int? _mark;
  int _totalDelta = 0;
  int _wake = 0;
  M3ServiceDropTool? _tool;
  final List<(int, Offset)> _taps = [];
  int _tapN = 0;

  /// A wrong way into the meter box, shown under its slip card.
  M3ServiceDropEntry? _wrongEntry;

  M3ServiceDropSpot _from = M3ServiceDropSpot.lane;
  M3ServiceDropSpot _to = M3ServiceDropSpot.lane;

  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// Gesture hints (how, never what) and the tool chips they sweep over.
  final _hints = IdleHintController();
  final _toolKeys = {for (final t in M3ServiceDropTool.values) t: GlobalKey()};

  /// The scene's geometry as last laid out (the hint anchors on it).
  M3ServiceDropGeo? _geoNow;

  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _move.dispose();
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

  String get _task => M3ServiceDropLines.ask(_run.station, laid: _run.cableOn);

  void _start() {
    _clock.start();
    unawaited(_sayChain([_task]));
  }

  /// The scene takes a move now: never in a right move's praise window
  /// (`tableBusy`: its ◆ wait on the table, or its reason deck).
  /// Nor once this station is won and waits for the walk on ([_stationWon]:
  /// the gap between এগিয়ে যান and [_nextStation]).
  bool get _canPlay => !_intro && !_ended && _card == null && !reasonOpen && !coworkerOpen && !struckOut && !_move.isAnimating && !tableBusy && !_stationWon;

  /// This station's right move is made: a second tap on its control (another
  /// drum, another way into the box) must never count again.
  bool get _stationWon => switch (_run.station) {
        M3ServiceDropStation.cable => _run.taken != null,
        M3ServiceDropStation.bearer => _run.clipped,
        M3ServiceDropStation.loop => _run.done,
      };

  /// The tool bag is out for the whole span station (the first tool laid on
  /// the span waits for the coworker: [holdForCoworker] in [_tapSpan]).
  bool get _trayReady => _run.station == M3ServiceDropStation.bearer && !_run.clipped;

  bool _used(M3ServiceDropTool t) => switch (t) {
        M3ServiceDropTool.bearer => _run.bearer,
        M3ServiceDropTool.cable => _run.cableOn,
        M3ServiceDropTool.clip => _run.clipped,
      };

  /// The hand for now: a sweep over every drum / tool / way into the box (never
  /// one of them). A tap only on the single way forward: the last tool left,
  /// then the span once it is in hand. While two or more tools are left the
  /// hand sweeps over them, tool in hand or not, so it never tells a right
  /// tool from a wrong one and never pushes a wrong-order lay (a slip).
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    switch (_run.station) {
      case M3ServiceDropStation.cable:
        return HintSpec.sweep([for (var i = 0; i < _run.deal.drums.length; i++) geo.drumRect(i)], space: HintSpace.scene);
      case M3ServiceDropStation.bearer:
        final left = [for (final t in _run.deal.tools) if (!_used(t)) t];
        if (left.isEmpty) return null;
        if (left.length == 1) {
          return _tool == left.single ? HintSpec.tap(geo.spanRect.center, space: HintSpace.scene) : HintSpec.tapOn(_toolKeys[left.single]!);
        }
        return HintSpec.sweepOver([for (final t in left) _toolKeys[t]!]);
      case M3ServiceDropStation.loop:
        return HintSpec.sweep([for (final e in M3ServiceDropEntry.values) geo.entryRect(e)], space: HintSpace.scene);
    }
  }

  // --- taps on the scene ---------------------------------------------------------
  void _pickTool(M3ServiceDropTool t) {
    if (!_canPlay || !_trayReady) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.wav', volume: 0.45);
    setState(() => _tool = _tool == t ? null : t);
  }

  void _tapScene(Offset p, M3ServiceDropGeo geo, Offset global) {
    if (!_canPlay) return;
    switch (_run.station) {
      case M3ServiceDropStation.cable:
        for (var i = 0; i < _run.deal.drums.length; i++) {
          if (geo.drumRect(i).contains(p)) {
            _takeDrum(i, global);
            return;
          }
        }
        _plainTap(p);
      case M3ServiceDropStation.bearer:
        _tapSpan(p, geo, global);
      case M3ServiceDropStation.loop:
        for (final e in M3ServiceDropEntry.values) {
          if (geo.entryRect(e).contains(p)) {
            _route(e, global);
            return;
          }
        }
        _plainTap(p);
    }
  }

  void _plainTap(Offset p) {
    _hints.missTap();
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.4);
    setState(() {
      _taps.add((_tapN++, p));
      if (_taps.length > 4) _taps.removeAt(0);
    });
  }

  void _takeDrum(int i, Offset global) {
    final m = _run.takeDrum(i);
    if (m != null) {
      unawaited(_slipOut(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.6);
    setState(() => _wake++);
    _stationRight(global);
  }

  void _tapSpan(Offset p, M3ServiceDropGeo geo, Offset global) {
    if (!_trayReady || !geo.spanRect.contains(p) || _tool == null) {
      _plainTap(p);
      return;
    }
    // The decisive control: a tool laid on the span waits for him (a fast
    // player still meets him before anything is hung).
    if (holdForCoworker()) return;
    final r = _run;
    switch (_tool) {
      case M3ServiceDropTool.bearer:
        if (r.stringBearer()) {
          _placed('sounds/intro/click.ogg');
          return;
        }
      case M3ServiceDropTool.cable:
        final m = r.layCable();
        if (m != null) {
          unawaited(_slipOut(m, global));
          return;
        }
        if (r.cableOn) {
          _placed('sounds/learn/tag_slap.wav');
          unawaited(_sayChain([M3ServiceDropLines.askClip]));
          return;
        }
      case M3ServiceDropTool.clip:
        // The clips before the cable: a wrong-order probe costs a slip.
        final m = r.clip();
        if (m != null) {
          unawaited(_slipOut(m, global));
          return;
        }
        if (r.clipped) {
          _placed('sounds/intro/click.ogg');
          _stationRight(global);
          return;
        }
      case null:
        break;
    }
    _plainTap(p);
  }

  void _placed(String sound) {
    HapticFeedback.mediumImpact();
    _cue(sound, volume: 0.65);
    setState(() {
      _tool = null;
      _wake++;
    });
  }

  void _route(M3ServiceDropEntry e, Offset global) {
    final m = _run.route(e);
    if (m != null) {
      setState(() => _wrongEntry = e);
      unawaited(_slipOut(m, global));
      return;
    }
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.wav', volume: 0.6);
    setState(() => _wake++);
    _stationRight(global);
  }

  Future<void> _moveTo(M3ServiceDropSpot s) async {
    if (s == _to) return;
    setState(() {
      _from = _to;
      _to = s;
      _wake++;
    });
    if (_quiet) {
      _move.value = 1;
    } else {
      await _move.forward(from: 0);
    }
    // The walk is over: rebuild the overlays that wait on it (the tool bag,
    // the hint's waiting state, the trainee's pose).
    if (mounted) setState(() => _wake++);
  }

  // --- a station done right: the ◆ and the reason ---------------------------------
  void _stationRight(Offset origin) {
    _hush();
    _cue('sounds/quiz_right.wav', volume: 0.6);
    final station = _run.station;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(askReason(
      deal: () => M3ServiceDropLines.dealWhy(station, widget.rng, three: _run.deal.three),
      question: M3ServiceDropLines.why(station),
      stillValid: () => _run.station == station && !_ended,
    ));
  }

  Future<void> _nextStation() async {
    if (_run.station == M3ServiceDropStation.loop) {
      unawaited(_finish());
      return;
    }
    _run.next();
    setState(() {
      _taps.clear();
      _tool = null;
      _wake++;
    });
    // He is armed before the climb (he waits out the walk: coworkerCanCome),
    // so the span's first tool always finds him due.
    if (_run.station == M3ServiceDropStation.bearer) scheduleCoworker();
    await _moveTo(_run.station == M3ServiceDropStation.bearer ? M3ServiceDropSpot.pole : M3ServiceDropSpot.wall);
    if (!mounted || _ended) return;
    unawaited(_sayChain([_task]));
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
      if (mounted && !_ended && _run.station == st) unawaited(_nextStation());
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M3ServiceDropLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.station.index > M3ServiceDropStation.bearer.index) return null;
    if (_run.station != M3ServiceDropStation.bearer) return false;
    // His push ("no bearer, tie the cable taut") no longer fits once a bearer
    // or the cable is up.
    if (_run.bearer || _run.cableOn || _run.clipped) return null;
    // Never in a praise window (tableBusy), a card, a deck or the walk.
    if (_intro || _card != null || reasonOpen || struckOut || _move.isAnimating || tableBusy) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      await _slipOut(_run.listenTaut(), origin);
      return;
    }
    _run.caught.add(M3ServiceDropLines.caughtCall);
    setState(() => _wake++);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    await coworkerSnarl();
    if (mounted && !_ended && _card == null) unawaited(_sayChain([_task]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    // Beat 1 is his alone (playbook §1.8): the guide stays idle until he has
    // spoken and the deck rises.
    if (coworkerOpen && !coworkerChoiceUp) return;
    // Nor over the praise line (the ◆ on the table, no deck yet), nor in the
    // gap after এগিয়ে যান while the station is won and the walk is due.
    if (!reasonOpen && (tableBusy || _stationWon)) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M3ServiceDropLines.tapWhy[_nudgeN++ % M3ServiceDropLines.tapWhy.length]
            : _nudge.next(_task);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
    unawaited(_sayChain([line]));
  }

  // --- mistakes ---------------------------------------------------------------
  Future<void> _slipOut(DoMistake m, Offset origin) async {
    setState(() => _tool = null);
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
    final speak = await SpokenOnce.first('m3_service_drop/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    _hush();
    setState(() {
      _card = null;
      _wrongEntry = null;
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
    if (_ended && !_run.done) return;
    if (_mark != null) return;
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
    await _say(!_run.passed ? M3ServiceDropLines.fail : (_quickBonus ? M3ServiceDropLines.quick : M3ServiceDropLines.allSet),
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
    if (_move.isAnimating) return LinemanMode.walk;
    return _to == M3ServiceDropSpot.lane ? LinemanMode.idle : LinemanMode.hold;
  }

  Rect _traineeBox(M3ServiceDropGeo geo) => Rect.lerp(geo.spotBox(_from), geo.spotBox(_to), Curves.easeInOut.transform(_move.value))!;

  M3ServiceDropRig get _rig {
    final r = _run;
    return M3ServiceDropRig(
      drums: r.deal.drums,
      taken: r.taken,
      bearer: r.bearer,
      cableOn: r.cableOn,
      clipped: r.clipped,
      entry: r.entry ?? _wrongEntry,
    );
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M3ServiceDropGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final tb = _traineeBox(geo);
    final onPole = _to == M3ServiceDropSpot.pole && !_move.isAnimating;
    final routing = _run.station == M3ServiceDropStation.loop && !_run.done && _wrongEntry == null && !_move.isAnimating && !reasonOpen && _card == null;
    final drumTags = _run.station == M3ServiceDropStation.cable;
    return [
      Positioned.fill(
        key: const ValueKey('land'),
        child: RepaintBoundary(child: CustomPaint(painter: M3ServiceDropWorldPainter(geo: geo, rig: _rig))),
      ),
      if (drumTags)
        for (var i = 0; i < _run.deal.drums.length; i++)
          Positioned(
            key: ValueKey('tag-$i'),
            left: geo.tagAt(i).dx,
            top: geo.tagAt(i).dy,
            width: 60,
            child: IgnorePointer(child: _DrumTag(text: _run.deal.drums[i].four ? M3ServiceDropLines.four : M3ServiceDropLines.twin, taken: _run.taken == i)),
          ),
      if (onPole)
        Positioned.fill(
          key: const ValueKey('strap'),
          child: IgnorePointer(child: CustomPaint(painter: M3ServiceDropStrapPainter(box: tb))),
        ),
      Positioned.fromRect(
        key: const ValueKey('trainee'),
        rect: tb,
        child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
      ),
      if (_run.done)
        Positioned.fill(
          key: const ValueKey('drip'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 1800),
              builder: (_, v, _) => CustomPaint(painter: M3ServiceDropDripPainter(geo: geo, v: v)),
            ),
          ),
        ),
      for (final (id, p) in _taps)
        Positioned(
          key: ValueKey('tap-$id'),
          left: p.dx - 14,
          top: p.dy - 14,
          width: 28,
          height: 28,
          child: IgnorePointer(child: _Ring(quiet: quiet)),
        ),
      // The ways into the meter box: three plain rings, the same for each.
      if (routing)
        for (final e in M3ServiceDropEntry.values)
          Positioned.fromRect(
            key: ValueKey('entry-${e.name}'),
            rect: geo.entryRect(e),
            child: IgnorePointer(child: _Ring(quiet: quiet, big: true)),
          ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M3ServiceDropLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
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
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null && !_run.ended && !_move.isAnimating && !tableBusy && !_stationWon;
    final st = _run.station;
    final tray = handsOn && _trayReady;
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
              labels: M3ServiceDropLines.rounds,
              done: {for (var i = 0; i < st.index; i++) i, if (_run.done) 2},
              current: _run.done ? null : st.index,
              quiet: quiet,
            ),
            animation: _move,
            hint: _hint,
            hintWaiting: handsOn && !coworkerOnScreen,
            hintKey: '${st.name}/${_tool?.name}/${_run.bearer}/${_run.cableOn}/${_run.slips}',
            hintController: _hints,
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !coworkerOpen)
                Positioned(
                  key: const ValueKey('docket'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(three: _run.deal.three)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (tray)
                Positioned(
                  key: const ValueKey('hud-tray'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 14,
                  child: Row(
                    children: [
                      // Dealt in a shuffled order (never bearer → cable → clips).
                      for (final (i, t) in _run.deal.tools.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _ToolChip(
                            key: _toolKeys[t],
                            label: switch (t) {
                              M3ServiceDropTool.bearer => M3ServiceDropLines.bearer,
                              M3ServiceDropTool.cable => M3ServiceDropLines.cable,
                              M3ServiceDropTool.clip => M3ServiceDropLines.clip,
                            },
                            icon: switch (t) {
                              M3ServiceDropTool.bearer => Icons.linear_scale_rounded,
                              M3ServiceDropTool.cable => Icons.cable_rounded,
                              M3ServiceDropTool.clip => Icons.attach_file_rounded,
                            },
                            selected: _tool == t,
                            used: _used(t),
                            onTap: () => _pickTool(t),
                          ),
                        ),
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
                    child: reasonOpen ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck')) : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (tray ? 76 : 20)), onLeft: coworkerFromRight),
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
                  line: M3ServiceDropLines.intro,
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

/// The docket: the job, the connection's phase and that the line is dead.
class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.three});
  final bool three;

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
          Text(M3ServiceDropLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(M3ServiceDropLines.job, style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
          Text(three ? M3ServiceDropLines.three : M3ServiceDropLines.single, style: bangla(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF8E3B12))),
          Text(M3ServiceDropLines.permit, style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E6B3A))),
        ],
      ),
    );
  }
}

/// The tag on a drum (what a worker reads: the cable's cores).
class _DrumTag extends StatelessWidget {
  const _DrumTag({required this.text, required this.taken});
  final String text;
  final bool taken;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: taken ? SlmColors.success : const Color(0xFF8A7A55), width: taken ? 2 : 1),
        ),
        child: Text(text, style: bangla(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
      ),
    );
  }
}

/// A tool from the bag: tap to take it, then tap the span.
class _ToolChip extends StatelessWidget {
  const _ToolChip({super.key, required this.label, required this.icon, required this.selected, required this.used, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = used ? SlmColors.success : (selected ? SlmColors.gold300 : const Color(0x99FFFFFF));
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: used ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xF21C2E4A) : const Color(0xE60B1324),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ring, width: selected ? 2.4 : 1.4),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(used ? Icons.check_circle_rounded : icon, size: 20, color: ring),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain white ring (a tap, or a way the cable could go).
class _Ring extends StatelessWidget {
  const _Ring({required this.quiet, this.big = false});
  final bool quiet;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.scale(scale: 1.4 - 0.4 * v, child: Opacity(opacity: (0.4 + 0.6 * v).clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: big ? const Color(0x33FFFFFF) : const Color(0x22FFFFFF),
          border: Border.all(color: const Color(0xEEFFFFFF), width: big ? 2.6 : 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
        ),
      ),
    );
  }
}
