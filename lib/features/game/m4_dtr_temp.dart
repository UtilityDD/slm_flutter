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
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode, Carry;
import 'm4_dtr_temp_world.dart';
import 'spoken_once.dart';

export 'm4_dtr_temp_world.dart' show M4DtrTempCase, M4DtrTempGeo, M4DtrTempLook;

// Lesson 4.5 "ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা", কাজ 2 "গরম
// কতটা?" (pack do_4_5_b). Three distribution transformers a play, each with
// its own story dealt fresh: overloaded, its cooling fins choked by creepers,
// low on oil, or just normally warm on a summer noon (the myth buster: a
// running transformer is always warm). Hands on, each job:
//   1. measure (choose + say no): the infrared thermometer — never a hand on
//      the tank (film 4.5 S3_03: "তাপ মাপতে ট্যাঙ্কে হাত দেবেন না; দূর থেকে
//      ইনফ্রারেড থার্মোমিটারে মাপুন"). A hand on the tank is deadly;
//   2. aim it at the tank from outside the fence (tap the tank);
//   3. read: normal warmth or overheating? (the thermometer's heat bar, the
//      shimmer over the tank). Calling it wrong is a slip either way;
//   4. overheating only — find the cause (spot): tap the oil gauge, the fins,
//      the LT cables (clamp meter + nameplate); a fine spot shows fine and is
//      not scored; the real cause opens 5;
//   5. decide (choose): report for load reduction / a bigger transformer;
//      clean the fins (on a shutdown — flagged); report the low oil for the
//      leak and the top-up. A wrong decision is a slip.
// Shared kit: guide first, full scene, corner guide, ◆ on the table →
// "কেন …?" → the next transformer by itself; the careless coworker once a
// play at the measure step ("হাত দিয়ে ছুঁয়ে দেখো কত গরম") — listening is the
// deadly hand on the tank. His new line goes by device TTS until recorded
// (listed in [M4DtrTempLines.recordLines]).

// ============================================================================
// Content
// ============================================================================

/// The steps of a job.
enum M4DtrTempPhase { measure, aim, read, find, act, done }

/// What a reason card asks about.
enum M4DtrTempTopic { measure, cause }

/// The two ways to "measure".
enum M4DtrTempTool { ir, hand }

@immutable
class M4DtrTempJob {
  const M4DtrTempJob({required this.kase, required this.topic});
  final M4DtrTempCase kase;
  final M4DtrTempTopic topic;

  bool get hot => kase != M4DtrTempCase.normal;

  /// The spot that shows the cause (null when nothing is wrong).
  M4DtrTempLook? get cause => switch (kase) {
    M4DtrTempCase.normal => null,
    M4DtrTempCase.overload => M4DtrTempLook.load,
    M4DtrTempCase.fins => M4DtrTempLook.fins,
    M4DtrTempCase.lowOil => M4DtrTempLook.gauge,
  };
}

@immutable
class M4DtrTempDeal {
  const M4DtrTempDeal({required this.jobs, required this.callAt});
  final List<M4DtrTempJob> jobs;

  /// The job the careless coworker comes on.
  final int callAt;
}

/// Three transformers: always one overloaded, then two of fins / low oil /
/// normal, in a fresh order; the reason topics dealt too.
M4DtrTempDeal m4DtrTempDeal(math.Random rng) {
  final rest = [M4DtrTempCase.fins, M4DtrTempCase.lowOil, M4DtrTempCase.normal]..shuffle(rng);
  final cases = [M4DtrTempCase.overload, rest[0], rest[1]]..shuffle(rng);
  return M4DtrTempDeal(
    jobs: [
      for (final k in cases) M4DtrTempJob(kase: k, topic: rng.nextBool() ? M4DtrTempTopic.measure : M4DtrTempTopic.cause),
    ],
    callAt: rng.nextInt(3),
  );
}

abstract final class M4DtrTempLines {
  static const title = 'গরম কতটা?';
  static const intro = 'গরমের দুপুর। তিনটে ট্রান্সফরমারের জ্বর মাপুন — দূর থেকে, নিয়ম মেনে।';
  static const rounds = ['ক', 'খ', 'গ'];

  // The task of each step (what the guide says and repeats when tapped).
  static const askMeasure = 'ট্রান্সফরমার কতটা গরম? কী দিয়ে মাপবেন?';
  static const askAim = 'বেড়ার বাইরে থেকেই ট্যাঙ্কে তাক করুন।';
  static const askRead = 'রিডিং দেখুন — গরমটা স্বাভাবিক, না অতিরিক্ত?';
  static const askFind = 'এত গরম কেন? কারণটা খুঁজে বের করুন।';
  static const askAct = 'কারণ পেলেন। এখন কী করবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];
  static String ask(M4DtrTempPhase p) => switch (p) {
    M4DtrTempPhase.measure => askMeasure,
    M4DtrTempPhase.aim => askAim,
    M4DtrTempPhase.read => askRead,
    M4DtrTempPhase.find => askFind,
    M4DtrTempPhase.act || M4DtrTempPhase.done => askAct,
  };
  static const tasks = [askMeasure, askAim, askRead, askFind, askAct];

  // Labels a worker reads (buttons, the docket).
  static const sceneLabel = 'ট্রান্সফরমারের ইয়ার্ড';
  static const ir = 'ইনফ্রারেড থার্মোমিটার';
  static const hand = 'হাতে ছুঁয়ে দেখা';
  static const normal = 'স্বাভাবিক গরম';
  static const over = 'অতিরিক্ত গরম';
  static const docket = 'ডকেট';
  static String jobBn(int i) => 'ট্রান্সফরমার ${rounds[i]} · তাপমাত্রা পরীক্ষা';
  static String lookBn(M4DtrTempLook l) => switch (l) {
    M4DtrTempLook.ir => 'ইনফ্রারেড থার্মোমিটার',
    M4DtrTempLook.gauge => 'কনজারভেটরের অয়েল গেজ',
    M4DtrTempLook.fins => 'কুলিং ফিন',
    M4DtrTempLook.load => 'লোড · ক্ল্যাম্প মিটার',
  };

  // Not scored: the guide says what to do, the step stays.
  static const missAim = 'থার্মোমিটারটা ট্যাঙ্কের গায়েই তাক করুন।';
  static const allFine = 'এখানে সব ঠিক আছে। আর কোথায় দেখবেন?';

  // The decision (step 5): the right ones are the lesson's actions for the
  // cause found; the wrong ones are wrong for every cause.
  static const actLoad = ['লোড কমাতে রিপোর্ট করি, দরকারে বড় ট্রান্সফরমার', 'লোড কমানো বা ক্ষমতা বাড়ানোর জন্য রিপোর্ট দিই'];
  static const actFins = ['শাটডাউন নিয়ে ফিনের লতাপাতা পরিষ্কার করাই', 'লাইন বন্ধ করিয়ে তারপর কুলিং ফিন সাফ করি'];
  static const actOil = ['সুপারভাইজারকে রিপোর্ট — লিক সারানো ও তেল টপ-আপ', 'এখনই রিপোর্ট করি, লিক সারিয়ে তেল টপ-আপ হবে'];
  static List<String> actRight(M4DtrTempCase k) => switch (k) {
    M4DtrTempCase.overload => actLoad,
    M4DtrTempCase.fins => actFins,
    M4DtrTempCase.lowOil || M4DtrTempCase.normal => actOil,
  };
  static const actWrong = [
    'হাতের কাছে ইঞ্জিন অয়েল আছে, সেটাই ঢেলে দিই',
    'লাইন চালু রেখেই ফিনের লতা টেনে ছিঁড়ে দিই',
    'গরম তো হবেই, কাউকে কিছু না বলে চলে যাই',
    'ঠান্ডা করতে ট্যাঙ্কের গায়ে বালতি ভরে জল ঢালি',
    'বিকেলে ঠান্ডা পড়লে নিজে থেকেই ঠিক হয়ে যাবে',
    'চালু অবস্থাতেই ঢাকনা খুলে তেল ভরে দিই',
  ];

  // The reasons (lesson 4.5 + film): the right ones fit the step asked; the
  // wrong ones are the lesson's myths and field excuses — never a true rule.
  static const whyMeasure = 'কেন হাত না দিয়ে দূর থেকে মাপলেন?';
  static const whyNormal = 'কেন বললেন এই গরম স্বাভাবিক?';
  static const whyLoad = 'কেন লোড কমানোর রিপোর্ট করলেন?';
  static const whyFins = 'কেন ফিন পরিষ্কার করালেন?';
  static const whyOil = 'কেন সঙ্গে সঙ্গে রিপোর্ট করলেন?';
  static String why(M4DtrTempJob j) => j.topic == M4DtrTempTopic.measure
      ? whyMeasure
      : switch (j.kase) {
          M4DtrTempCase.normal => whyNormal,
          M4DtrTempCase.overload => whyLoad,
          M4DtrTempCase.fins => whyFins,
          M4DtrTempCase.lowOil => whyOil,
        };

  static const measureWhy = ['গরম ট্যাঙ্কে হাত দেওয়া মানে নিজের বিপদ ডাকা', 'ইনফ্রারেড থার্মোমিটার দূর থেকেই তাপ মাপে'];
  static const normalWhy = ['চলার সময় ট্রান্সফরমার কিছুটা গরম হবেই', 'গরমের দুপুরে, পিক লোডে একটু গরম স্বাভাবিক'];
  static const loadWhy = ['বেশি লোডে কপার লস বেড়ে ট্রান্সফরমার তাতে', 'ওভারলোডিং-ই অতিরিক্ত গরমের প্রধান কারণ'];
  static const finsWhy = ['ফিনে বাতাস লাগলে তবেই তেল দ্রুত ঠান্ডা হয়', 'লতাপাতায় ঢাকা ফিনে হাওয়া চলাচল বন্ধ থাকে'];
  static const oilWhy = ['তেল কমলে ওয়াইন্ডিং তেলের বাইরে চলে আসে', 'মিনিমামের নিচে তেল মানে গুরুতর বিপদ সংকেত'];
  static List<String> whyRight(M4DtrTempJob j) => j.topic == M4DtrTempTopic.measure
      ? measureWhy
      : switch (j.kase) {
          M4DtrTempCase.normal => normalWhy,
          M4DtrTempCase.overload => loadWhy,
          M4DtrTempCase.fins => finsWhy,
          M4DtrTempCase.lowOil => oilWhy,
        };

  /// Wrong reasons (the lesson's myths and field excuses).
  static const whyWrong = [
    'গরম হওয়া মানেই ট্রান্সফরমার খারাপ হয়ে গেছে',
    'যেকোনো তেল ঢাললেই ট্রান্সফরমার চলে যায়',
    'অভ্যাস আছে, হাত দিলেই সব বোঝা যায়',
    'সুপারভাইজার তাড়া দিচ্ছেন, তাই তাড়াতাড়ি',
    'রিপোর্ট লাগে না, মুখে বলে দিলেই হবে',
    'গরম হলে লোড নিজে থেকেই কমে যায়, চিন্তা নেই',
  ];

  /// The careless coworker, at the measure step.
  static const coworkerExit = 'হুঁ! যা খুশি করো।';
  static const coworker = CoworkerScript(
    line: 'যন্ত্র-টন্ত্র লাগবে না! হাত দিয়ে ছুঁয়ে দেখো কত গরম।',
    exitLine: coworkerExit,
    right: ['না, ট্যাঙ্কে হাত নয়, দূর থেকে মাপব', 'না, ইনফ্রারেড থার্মোমিটারেই মাপছি', 'হাত দিয়ে নয়, যন্ত্র দিয়ে দূর থেকে'],
    wrong: [
      'ঠিক, হাত রাখলেই তো বোঝা যাবে',
      'আচ্ছা, একবার হাতে ছুঁয়েই দেখি',
      'যন্ত্র আনতে দেরি, হাতেই দেখি',
      'ঠিক আছে, তালু চেপে দেখে নিচ্ছি',
      'ট্যাঙ্কে হাত দিলে কিছু হয় না',
    ],
    asks: ['ও বলছে হাত দিয়ে ছুঁয়ে দেখতে। আপনি?', 'কী দিয়ে মাপবেন — ওর কথায়, না নিয়মে?', 'ওর কথা শুনবেন, না নিয়ম মানবেন?'],
  );

  /// New lines for him (device TTS until recorded in his voice).
  static List<String> get recordLines => [coworker.line, coworkerExit];

  static const callHeld = 'ঠিক! চাপে পড়ে নিয়ম ভাঙবেন না।';
  static const putRightHot = 'এটা অতিরিক্ত গরম। এবার কারণ খুঁজুন।';
  static const allSet = 'দূর থেকে মাপা, ঠিক পড়া, কারণ ধরা — ট্রান্সফরমারের ডাক্তার হয়ে গেলেন।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — দূর থেকে মাপুন, ঠিক পড়ুন, তারপর কারণ।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtIr = 'হাত নয় — দূর থেকে ইনফ্রারেডে মাপা';
  static const caughtRead = 'স্বাভাবিক আর অতিরিক্ত গরমের তফাত';
  static const caughtLoad = 'ওভারলোড — লোড কমানোর রিপোর্ট';
  static const caughtFins = 'ঢাকা ফিন — শাটডাউনে পরিষ্কার';
  static const caughtOil = 'মিনিমামের নিচে তেল — সঙ্গে সঙ্গে রিপোর্ট';
  static const caughtCall = 'চাপে “না” বলেছেন';
}

abstract final class M4DtrTempMistakes {
  static const _dir = 'assets/game/art/m4_dtr_temp';

  static const handOnTank = DoMistake(
    key: '4.5/m4_dtr_temp/hand-on-tank',
    textBn: 'চালু ট্রান্সফরমারের ট্যাঙ্কে হাত দিলেন। গরম ট্যাঙ্ক পুড়িয়ে দেয়, আর আর্থ ঠিক না থাকলে বডিতেই কারেন্ট — তাপ মাপুন দূর থেকে, ইনফ্রারেড থার্মোমিটারে।',
    art: '$_dir/dt_hand.svg',
    deadly: true,
    lessonPoint: 1,
  );
  static const missedHot = DoMistake(
    key: '4.5/m4_dtr_temp/missed-overheat',
    textBn: 'অতিরিক্ত গরমকে স্বাভাবিক বললেন। বেশি গরম ভেতরের কাগজের ইনসুলেশনের আয়ু দ্রুত কমায় — এটা ওভারলোড বা ভেতরের ফল্টের লক্ষণ।',
    art: '$_dir/dt_read.svg',
    lessonPoint: 1,
  );
  static const mythHot = DoMistake(
    key: '4.5/m4_dtr_temp/normal-called-hot',
    textBn: 'স্বাভাবিক গরমকে বিপদ বললেন। চলার সময় ট্রান্সফরমার তাপ তৈরি করবেই — গরমের দুপুরে, পিক লোডে একটু বেশি গরম স্বাভাবিক।',
    art: '$_dir/dt_read.svg',
    lessonPoint: 1,
  );
  static const wrongLoad = DoMistake(
    key: '4.5/m4_dtr_temp/overload-wrong-action',
    textBn: 'ওভারলোডের ভুল ব্যবস্থা নিলেন। লোড পরীক্ষা করুন; ওভারলোড হলে লোড কমানো বা ট্রান্সফরমারের ক্ষমতা বাড়ানোর জন্য রিপোর্ট করুন।',
    art: '$_dir/dt_load.svg',
    lessonPoint: 2,
  );
  static const wrongFins = DoMistake(
    key: '4.5/m4_dtr_temp/fins-wrong-action',
    textBn: 'ঢাকা ফিনের ভুল ব্যবস্থা নিলেন। লতাপাতায় ঢাকা ফিনে বাতাস লাগে না, তেল ঠান্ডা হয় না — লাইন বন্ধ করিয়ে ফিন পরিষ্কার করুন।',
    art: '$_dir/dt_fins.svg',
    lessonPoint: 2,
  );
  static const wrongOil = DoMistake(
    key: '4.5/m4_dtr_temp/low-oil-wrong-action',
    textBn: 'কম তেলের ভুল ব্যবস্থা নিলেন। অবিলম্বে সুপারভাইজারকে রিপোর্ট — লিক সারানো আর লাইন বন্ধ করে একই গ্রেডের ফিল্টার করা তেলে টপ-আপ।',
    art: '$_dir/dt_oil.svg',
    lessonPoint: 0,
  );
  static DoMistake wrongAct(M4DtrTempCase k) => switch (k) {
    M4DtrTempCase.overload => wrongLoad,
    M4DtrTempCase.fins => wrongFins,
    M4DtrTempCase.lowOil || M4DtrTempCase.normal => wrongOil,
  };

  static List<DoMistake> get all => const [handOnTank, missedHot, mythHot, wrongLoad, wrongFins, wrongOil];
}

/// The play state (pure logic).
class M4DtrTempRun {
  M4DtrTempRun(this.deal);
  final M4DtrTempDeal deal;
  int index = 0;
  M4DtrTempPhase phase = M4DtrTempPhase.measure;
  final Set<M4DtrTempLook> checked = {};
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.jobs.length;
  bool get ended => done || deadly != null;
  M4DtrTempJob get job => deal.jobs[index.clamp(0, deal.jobs.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get clean => jobSlips == 0;

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  /// Pick how to measure: a hand on the tank is deadly.
  DoMistake? pick(M4DtrTempTool t) {
    if (ended || phase != M4DtrTempPhase.measure) return null;
    if (t == M4DtrTempTool.hand) return deadly = M4DtrTempMistakes.handOnTank;
    _tag(M4DtrTempLines.caughtIr);
    phase = M4DtrTempPhase.aim;
    return null;
  }

  /// The thermometer on the tank: on to the reading.
  void aim() {
    if (!ended && phase == M4DtrTempPhase.aim) phase = M4DtrTempPhase.read;
  }

  /// Normal or overheating? Wrong either way is a slip; a hot one goes on
  /// to the cause, a normal one is done.
  DoMistake? judge({required bool hot}) {
    if (ended || phase != M4DtrTempPhase.read) return null;
    final j = job;
    phase = j.hot ? M4DtrTempPhase.find : M4DtrTempPhase.done;
    if (hot != j.hot) return _slip(j.hot ? M4DtrTempMistakes.missedHot : M4DtrTempMistakes.mythHot);
    _tag(M4DtrTempLines.caughtRead);
    return null;
  }

  /// Look at a spot: true when it shows the cause (on to the decision).
  bool check(M4DtrTempLook l) {
    if (ended || phase != M4DtrTempPhase.find || l == M4DtrTempLook.ir) return false;
    checked.add(l);
    if (l != job.cause) return false;
    phase = M4DtrTempPhase.act;
    return true;
  }

  /// The decision: a wrong one is a slip; the job is done either way.
  DoMistake? act({required bool right}) {
    if (ended || phase != M4DtrTempPhase.act) return null;
    final k = job.kase;
    phase = M4DtrTempPhase.done;
    if (!right) return _slip(M4DtrTempMistakes.wrongAct(k));
    _tag(switch (k) {
      M4DtrTempCase.overload => M4DtrTempLines.caughtLoad,
      M4DtrTempCase.fins => M4DtrTempLines.caughtFins,
      M4DtrTempCase.lowOil || M4DtrTempCase.normal => M4DtrTempLines.caughtOil,
    });
    return null;
  }

  void next() {
    index++;
    phase = M4DtrTempPhase.measure;
    checked.clear();
    jobSlips = 0;
  }
}

/// The quick bonus (~85 % of a thorough play, rounded to 10 s). A hot job:
/// tool 1500 + aim 2000 + read 3000 + find (two looks) 4000 + decide 6000
/// + reason 8200 ≈ 24700; a normal one ≈ 14700. Three jobs (one may be
/// normal) ≈ 64000–74000, + the coworker ≈ 9000 → ~80000; 85 % ≈ 68000 → 70 s.
const kM4DtrTempQuickMs = 70000;

@immutable
class M4DtrTempPack {
  const M4DtrTempPack({required this.id, required this.titleBn, this.quickMs = kM4DtrTempQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M4DtrTempPack> m4DtrTempPacks = {'do_4_5_b': M4DtrTempPack(id: 'do_4_5_b', titleBn: M4DtrTempLines.title)};

/// The trainee's box standing with his centre at [x].
Rect m4DtrTempTraineeBox(M4DtrTempGeo geo, double x) {
  final h = geo.man;
  return Rect.fromLTWH(x - h / 4, geo.groundY - h + 4, h / 2, h);
}

// ============================================================================
// Page
// ============================================================================

class M4DtrTempPage extends StatefulWidget {
  const M4DtrTempPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M4DtrTempPack pack;
  final bool muted;
  final int? seed;

  @override
  State<M4DtrTempPage> createState() => _M4DtrTempPageState();
}

class _M4DtrTempPageState extends State<M4DtrTempPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _DtRunPage(
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

class _DtRunPage extends ConsumerStatefulWidget {
  const _DtRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M4DtrTempPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_DtRunPage> createState() => _DtRunPageState();
}

class _DtRunPageState extends ConsumerState<_DtRunPage> with DoDeathGuard, DoStrikeOut, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M4DtrTempRun _run = M4DtrTempRun(m4DtrTempDeal(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  int _runScore = 0;
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
  int _wake = 0;

  /// The trainee's x (outside the fence; walks to the tank on the deadly).
  double _standX = M4DtrTempGeo.standX;

  /// The IR thermometer is in his hand; where its dot sits on the tank.
  var _gun = false;
  Offset? _aimAt;

  /// The close-up open now.
  M4DtrTempLook? _look;

  /// The decision deck.
  var _actOpen = false;
  List<ChoiceOption> _actOpts = const [];
  final Set<String> _actWrong = {};
  String? _actPicked;

  var _freeze = false;
  Completer<void>? _frozen;
  Offset? _deathAt;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  M4DtrTempJob get _job => _run.job;
  M4DtrTempGeo _geoNow = M4DtrTempGeo.forScene(780, 0);

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

  void _cue(String file, {double volume = 0.7}) {
    if (!_muted) unawaited(ZlFx.cue(file, volume: volume, muted: false));
  }

  bool get _canPlay => !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_actOpen;

  void _start() {
    _clock.start();
    _startJob();
  }

  void _startJob() {
    setState(() {
      _standX = M4DtrTempGeo.standX;
      _gun = false;
      _aimAt = null;
      _look = null;
      _actOpen = false;
      _wake++;
    });
    if (_run.index == _run.deal.callAt) scheduleCoworker();
    unawaited(_sayChain([M4DtrTempLines.askMeasure]));
  }

  void _askStep() => unawaited(_sayChain([M4DtrTempLines.ask(_run.phase)]));

  // --- 1. measure -----------------------------------------------------------------
  Future<void> _pick(M4DtrTempTool t) async {
    if (!_canPlay || _run.phase != M4DtrTempPhase.measure) return;
    _hush();
    final m = _run.pick(t);
    if (m != null) {
      await _deadly(m);
      return;
    }
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.5);
    setState(() {
      _gun = true;
      _wake++;
    });
    _askStep();
  }

  // --- 2. aim / 4. find -------------------------------------------------------------
  Future<void> _tapScene(Offset p) async {
    if (!_canPlay) return;
    final geo = _geoNow;
    switch (_run.phase) {
      case M4DtrTempPhase.aim:
        if (!geo.onTank(p)) {
          HapticFeedback.selectionClick();
          unawaited(_sayChain([M4DtrTempLines.missAim]));
          return;
        }
        HapticFeedback.mediumImpact();
        _cue('sounds/intro/tick.ogg', volume: 0.6);
        setState(() {
          _run.aim();
          _aimAt = p;
          _look = M4DtrTempLook.ir;
          _wake++;
        });
        _askStep();
      case M4DtrTempPhase.find:
        final l = geo.spotAt(p);
        if (l == null) return;
        HapticFeedback.selectionClick();
        _cue('sounds/intro/click.ogg', volume: 0.5);
        final cause = _run.check(l);
        setState(() {
          _look = l;
          _wake++;
        });
        if (!cause) {
          unawaited(_sayChain([M4DtrTempLines.allFine]));
          return;
        }
        _hush();
        final idx = _run.index;
        await _sayChain([M4DtrTempLines.askAct]);
        if (!mounted || _ended || _run.index != idx || _run.phase != M4DtrTempPhase.act || _actOpen) return;
        _openAct();
      case M4DtrTempPhase.measure || M4DtrTempPhase.read || M4DtrTempPhase.act || M4DtrTempPhase.done:
        break;
    }
  }

  // --- 3. read --------------------------------------------------------------------
  Future<void> _judge(bool hot, Offset origin) async {
    if (!_canPlay || _run.phase != M4DtrTempPhase.read) return;
    _hush();
    final m = _run.judge(hot: hot);
    HapticFeedback.mediumImpact();
    setState(() => _wake++);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _cue('sounds/intro/confirm.ogg', volume: 0.5);
    if (_run.phase == M4DtrTempPhase.done) {
      _jobDone();
      return;
    }
    setState(() => _look = null);
    _askStep();
  }

  // --- 5. decide ------------------------------------------------------------------
  void _openAct() {
    setState(() {
      _actOpts = dealChoices(M4DtrTempLines.actRight(_job.kase), M4DtrTempLines.actWrong, widget.rng);
      _actWrong.clear();
      _actPicked = null;
      _actOpen = true;
    });
  }

  Future<void> _pickAct(ChoiceOption o, Offset origin) async {
    if (!_actOpen || _actPicked != null || _ended || _card != null) return;
    _hush();
    final m = _run.act(right: o.correct);
    setState(() {
      if (o.correct) {
        _actPicked = o.textBn;
      } else {
        _actWrong.add(o.textBn);
      }
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 150 : 600));
    if (!mounted) return;
    setState(() => _actOpen = false);
    if (m != null) {
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _jobDone();
  }

  /// The job is done: its ◆ on the table, then "কেন …?".
  void _jobDone() {
    final j = _job;
    final idx = _run.index;
    putOnTable(15 + (_run.clean ? 5 : 0));
    unawaited(
      askReason(
        deal: () => dealChoices(M4DtrTempLines.whyRight(j), M4DtrTempLines.whyWrong, widget.rng),
        question: M4DtrTempLines.why(j),
        stillValid: () => _run.index == idx && !_ended,
      ),
    );
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
    unawaited(
      Future<void>.delayed(Duration(milliseconds: _quiet ? 300 : 700), () {
        if (mounted && !_ended && _run.index == idx) _next();
      }),
    );
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => M4DtrTempLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.phase != M4DtrTempPhase.measure) return null;
    if (_intro || _busy || _card != null || reasonOpen) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // His way: the palm on the tank.
      final m = _run.pick(M4DtrTempTool.hand);
      if (m != null) await _deadly(m);
      return;
    }
    _run.caught.add(M4DtrTempLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    unawaited(_sayChain([M4DtrTempLines.callHeld, M4DtrTempLines.ask(_run.phase)]));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
        ? M4DtrTempLines.tapWhy[_nudgeN++ % M4DtrTempLines.tapWhy.length]
        : _nudge.next(M4DtrTempLines.ask(_run.phase));
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.5);
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
    HapticFeedback.heavyImpact();
    _cue('sounds/quiz_wrong.wav');
    setState(() {
      _card = m;
      _cardTone = MistakeTone.slip;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('dttemp/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// He walks to the tank, puts his palm on it: the yard freezes grey, the
  /// flash in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    final geo = _geoNow;
    setState(() {
      _gun = false;
      _look = null;
      _standX = geo.tank.left - 14;
    });
    await Future<void>.delayed(Duration(milliseconds: _quiet ? 50 : 650));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    _cue('sounds/accident.wav', volume: 0.9);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _deathAt = Offset(geo.tank.left + 4, geo.groundY - 60);
    });
    await frozen.future;
    if (!mounted) return;
    final death = await bookDeadly(m, runScore: _runScore) == DeadlyOutcome.death;
    if (!mounted) return;
    setState(() {
      _card = m;
      _cardTone = death ? MistakeTone.deadly : MistakeTone.nearMiss;
    });
    final speak = await SpokenOnce.first('dttemp/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M4DtrTempLines.deadlyWord : M4DtrTempLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        // The guide put it right; the job goes on (or is done).
        if (_run.phase == M4DtrTempPhase.done) {
          _jobDone();
        } else {
          setState(() => _look = null);
          unawaited(_sayChain([if (_run.phase == M4DtrTempPhase.find) M4DtrTempLines.putRightHot else M4DtrTempLines.ask(_run.phase)]));
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
    await _say(
      !_run.passed ? M4DtrTempLines.fail : (_quickBonus ? M4DtrTempLines.quick : M4DtrTempLines.allSet),
      mood: _run.passed ? GuideMood.celebrate : GuideMood.warn,
    );
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
    if (_gun) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M4DtrTempGeo.forScene(m.height, m.inset);
    final j = _job;
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final tb = m4DtrTempTraineeBox(geo, _standX);
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('yard'),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: M4DtrTempWorldPainter(geo: geo, kase: j.kase),
                  ),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('trainee'),
                duration: Duration(milliseconds: quiet ? 0 : 600),
                curve: Curves.easeInOut,
                left: tb.left,
                top: tb.top,
                width: tb.width,
                height: tb.height,
                child: LinemanFigure(
                  look: LinemanLook.trainee,
                  mode: _mode,
                  wake: _wake,
                  quiet: quiet,
                ),
              ),
              if (_gun)
                Positioned.fill(
                  key: const ValueKey('gun'),
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: M4DtrTempGunPainter(hand: hand, aim: _aimAt),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Tap the tank, the gauge, the fins, the LT cables.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M4DtrTempLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => unawaited(_tapScene(d.localPosition)),
          ),
        ),
      ),
      // The flash at the palm, in colour over the grey yard.
      if (_freeze && _deathAt != null)
        Positioned.fill(
          key: const ValueKey('zap'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(
                painter: M4DtrTempZapPainter(at: _deathAt!, v: v),
              ),
            ),
          ),
        ),
      // The next transformer: a short fade.
      if (!_intro && !_freeze)
        Positioned.fill(
          key: ValueKey('job-${_run.index}'),
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
    final deckUp = reasonOpen || coworkerChoiceUp || _actOpen;
    final handsOn = playing && !deckUp && !coworkerOpen && _card == null;
    final phase = _run.phase;
    final look = _look;
    final showLook = playing && look != null && _card == null && !reasonOpen && tablePending == 0 && !coworkerOnScreen;
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
              labels: M4DtrTempLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            overlays: [
              if (playing && !_run.done && !coworkerOpen && !showLook)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(text: M4DtrTempLines.jobBn(_run.index.clamp(0, 2)))),
                ),
              if (showLook)
                _LookCard(
                  key: ValueKey('look-${look.name}-${_run.index}'),
                  look: look,
                  kase: _job.kase,
                  quiet: quiet,
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn && phase == M4DtrTempPhase.measure)
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 8,
                  right: 8,
                  bottom: pad.bottom + 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ToolButton(
                        icon: Icons.sensors_rounded,
                        label: M4DtrTempLines.ir,
                        enabled: _canPlay,
                        onTap: () => unawaited(_pick(M4DtrTempTool.ir)),
                      ),
                      const SizedBox(width: 18),
                      _ToolButton(
                        icon: Icons.back_hand_rounded,
                        label: M4DtrTempLines.hand,
                        enabled: _canPlay,
                        onTap: () => unawaited(_pick(M4DtrTempTool.hand)),
                      ),
                    ],
                  ),
                ),
              if (handsOn && phase == M4DtrTempPhase.read)
                Positioned(
                  key: const ValueKey('hud-read'),
                  left: 16,
                  right: 16,
                  bottom: pad.bottom + 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: DoBigButton(label: M4DtrTempLines.normal, filled: false, onDark: true, onTapUp: (d) => unawaited(_judge(false, d.globalPosition))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DoBigButton(label: M4DtrTempLines.over, filled: true, onTapUp: (d) => unawaited(_judge(true, d.globalPosition))),
                      ),
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
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : _actOpen
                        ? ChoiceDeck(
                            key: ValueKey('act-deck-${_run.index}'),
                            options: _actOpts,
                            quiet: quiet,
                            muted: _muted,
                            wrong: _actWrong,
                            picked: _actPicked,
                            onPick: (o, at) => unawaited(_pickAct(o, at)),
                          )
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null)
                cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : (handsOn && phase == M4DtrTempPhase.measure ? 128 : 84)), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
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
                  line: M4DtrTempLines.intro,
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

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.text});
  final String text;

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
          Text(
            M4DtrTempLines.docket,
            style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A)),
          ),
          Text(
            text,
            style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416)),
          ),
        ],
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const ring = SlmColors.gold300;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 128,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 28, color: ring),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: bangla(fontSize: 12, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close-up of what he is looking at (the thermometer's screen, the oil
/// gauge, the fins, the clamp meter with the nameplate).
class _LookCard extends StatelessWidget {
  const _LookCard({super.key, required this.look, required this.kase, required this.quiet});
  final M4DtrTempLook look;
  final M4DtrTempCase kase;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.paddingOf(context).top + 92,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(
              scale: 0.85 + 0.15 * v,
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              width: 236,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xE60B1324),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.6),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    M4DtrTempLines.lookBn(look),
                    style: bangla(fontSize: 12.5, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    key: const ValueKey('look-art'),
                    width: 220,
                    height: 120,
                    child: CustomPaint(
                      painter: M4DtrTempLookPainter(look: look, kase: kase),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
