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
import 'm6_fuse_gauge_world.dart';
import 'mistake_kit.dart';
import 'reason_table.dart';
import 'scene_kit.dart' show GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'spoken_once.dart';

export 'm6_fuse_gauge_world.dart' show M6FusePlace, M6FuseTool, m6AcsrSrc, m6GiSrc, m6PlateMm, m6Mm;

// Lesson 6.3 "ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব", কাজ 1 "মেপে তবেই
// বাঁধো" (pack do_6_3_a, engineType m6_fuse_gauge). Three kit-kat carriers
// to re-wire at a van's tailgate by a DTR pole (one from the old LT box —
// staged switched OFF, locked, tagged and proved dead, ruling X4 — one from
// a rural DB, one from a consumer's meter board; lesson 6.3 point 3). The
// docket gives the place, its isolation stamp (every carrier is pulled off a
// dead board: lesson 6.3 point 6, ruling X4) and the carrier's amps (IS 9926
// jobs 16/32/63/100 A, ruling X6). The four tinned-copper reels on the tray have their tags worn
// off and look alike: the trainee measures before he ties.
//
//  Measure (the core verb): drag a reel's end into a slot of the round gauge
//    plate (six slots, read in mm: the lesson's 0.50 / 0.85 / 1.50 / 2.00 and
//    two decoy sizes); too narrow it will not go in, too wide it rattles,
//    snug it seats with a click and his chalk number goes under that reel.
//    On the third job the plate is not on the bench: the micrometer instead
//    (drag the wire into its jaws, roll the thimble; mm readout only).
//  Fit: drag the measured wire to the carrier's top screw, then a short drag
//    down to the bottom screw (taut). Right → ◆ on the table → "কেন …?" → the
//    next carrier.
//
// Deadly (module 6 table R12; lesson 6.3 point 5 'চরম অপরাধ'): an ACSR
// aluminium strand or GI binding wire tied in a fuse's place (own pick, or
// on the coworker's word: ruling X2/B1). Slips (R13, M6-5): a tinned wire of
// the wrong diameter; a reel tied that was never measured snug; listening to
// 'মোটাটাই বাঁধো'. Three slips strike out.
//
// The twist job of the spec is dropped (ruling X6: the lesson gives no strand
// figure); the ACSR push comes at the first reel load on any job.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, the
// full scene (m6_fuse_gauge_world.dart), corner guide, a right tie puts ◆ on
// the table → the reason deck at once → এগিয়ে যান → next; the careless
// coworker once a play on his dealt job, at the first reel taken up (the
// next measuring or tying control waits for him: holdForCoworker). Gesture
// hands: a sweep over every wire alike, a drag nudge toward the plate's hub
// (never a slot), a sweep over the slots, the tray and the carrier, a swipe
// along the thimble, a short drag down from the top screw — never the answer.

// ============================================================================
// Content
// ============================================================================

/// The coworker's push (one per play).
enum M6FusePush { acsr, thick }

/// How a wire sat in a plate slot.
enum M6Fit { narrow, loose, snug }

/// The IS 9926 ratings of the jobs (lesson 6.3 point 4, live text).
const m6FuseAmps = [16, 32, 63, 100];

/// The right diameter for a rating, in hundredths of a mm.
int m6RightMm(int amps) => switch (amps) {
      16 => 50,
      32 => 85,
      63 => 150,
      _ => 200,
    };

/// Staging: an ACSR strand is far thicker than any fuse wire (lesson: 'ফিউজ
/// তারের চেয়ে অনেক মোটা'); the GI binding wire is no standard size and never
/// seats snug in the plate.
const m6AcsrMm = 300;
const m6GiMm = 100;

/// Which ratings a place's carrier may carry (staging: the lesson names the
/// places but gives no rating per place — see the report's open questions).
const m6PlaceAmps = <M6FusePlace, List<int>>{
  M6FusePlace.ltBox: [63, 100],
  M6FusePlace.ruralDb: [32, 63],
  M6FusePlace.meterBoard: [16, 32],
};

abstract final class M6FuseGaugeLines {
  static const title = 'মেপে তবেই বাঁধো';

  // DRAFT wording — owner (every new spoken line; recorded later).
  static const intro = 'তিনটে ক্যারিয়ারে নতুন ফিউজ তার বাঁধতে হবে — রিলের গায়ে লেখা নেই, মেপে নিন।';
  static const askPlate = 'ডকেট দেখুন। ঠিক তারটা গেজ প্লেটে মেপে বের করুন।';
  static const askMic = 'এবার গেজ প্লেট নেই — মাইক্রোমিটারে মেপে নিন।';
  static const askTie = 'তারটা ক্যারিয়ারের দুই স্ক্রুতে টানটান করে বাঁধুন।';
  static const tasks = [askPlate, askMic, askTie];
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // On the scene (words a worker reads).
  static const sceneLabel = 'বেঞ্চ, রিল আর কিট-ক্যাট ক্যারিয়ার';
  static const docketHead = 'ডকেট';
  static String place(M6FusePlace p) => switch (p) {
        M6FusePlace.ltBox => 'LT বক্স',
        M6FusePlace.ruralDb => 'গ্রামীণ ডিস্ট্রিবিউশন বোর্ড',
        M6FusePlace.meterBoard => 'গ্রাহকের মিটার বোর্ড',
      };

  /// The isolation stamp on every docket (lesson 6.3 point 6: supply switched
  /// off, lock-tag, proved dead before any fuse is pulled; ruling X4 — the
  /// meter board's own main switch).
  static String isolation(M6FusePlace p) => switch (p) {
        M6FusePlace.meterBoard => 'মেন সুইচ বন্ধ, তালা, 0 V',
        _ => 'বন্ধ, তালা, 0 V',
      };
  static String carrier(int amps) => 'কিট-ক্যাট · $amps A';
  static String fit(M6Fit f) => switch (f) {
        M6Fit.narrow => 'ঢোকে না',
        M6Fit.loose => 'ঢিলে',
        M6Fit.snug => 'খাপে খাপ',
      };
  static String source(int src) => src == m6AcsrSrc
      ? 'ACSR-এর টুকরো'
      : src == m6GiSrc
          ? 'জিআই বাইন্ডিং তার'
          : 'রিল ${src + 1}';
  static String slot(int k) => 'স্লট ${m6Mm(m6PlateMm[k])}';
  static const jaws = 'মাইক্রোমিটারের মুখ';
  static const thimble = 'মাইক্রোমিটারের থিম্বল';
  static const topScrew = 'ওপরের স্ক্রু';
  static const bottomScrew = 'নিচের স্ক্রু';

  // The reasons. Plate jobs: why this wire (the rule, no figures); the
  // micrometer job: the table recalled for the OTHER ratings (the docket
  // shows this job's amps, so no card names them or the size just measured).
  static const whyQPlate = 'কেন এই তারটা বাঁধলেন?';
  static const whyQMic = 'অন্য রেটিংয়ে কোন মাপের তার? ঠিকটা বাছুন।';
  static const whyRule = [
    'রেটিং মেনে ঠিক ব্যাসের তার, মেপে তবেই বাঁধা',
    'মাপে ব্যাস মিলেছে, ফল্টে এটাই ঠিক সময়ে গলবে',
    'আন্দাজে নয়, গেজে মেপে রেটিংয়ের তারটাই নিলাম',
  ];
  static const myths = [
    'মোটা তার দিলে ফিউজ মজবুত, বারবার উড়বে না',
    'চোখে দেখেই বোঝা যায়, মাপার দরকারই নেই',
    'হাতের কাছে যে রিল ছিল, সেটাই বেঁধে দিলাম',
    'গেজ নম্বর যত বড়, তার তত মোটা — তাই নিলাম',
    'সাময়িক কাজে যেকোনো তার দিলেই চলে যায়',
    'চিকন তার উড়ে যায়, তাই একটু মোটাই ভালো',
  ];
  static String micPair(int amps, int mm) => '$amps A-এর কাজে ${m6Mm(mm)} মিমি';

  /// The table's pairs for the ratings that are not this job's.
  static List<String> whyMicRight(int amps) => [
        for (final y in m6FuseAmps)
          if (y != amps) micPair(y, m6RightMm(y)),
      ];

  /// Those ratings, each paired with another of their sizes (never this
  /// job's size, which he just measured).
  static List<String> whyMicWrong(int amps) => [
        for (final y in m6FuseAmps)
          if (y != amps)
            for (final z in m6FuseAmps)
              if (z != amps && z != y) micPair(y, m6RightMm(z)),
      ];

  // The careless coworker (one push a play, at the first reel taken up on
  // his job). DRAFT wording — owner.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworkerAcsr = CoworkerScript(
    line: 'মাপামাপি ছাড়ো! ACSR থেকে একটা অ্যালুমিনিয়াম সুতো খুলে বেঁধে দাও — সাময়িক!',
    exitLine: coworkerExit,
    right: ['না, ACSR-এর সুতো ফিউজের জায়গায় নয়', 'না, মেপে টিনড কপার তারই বাঁধব', 'না, সাময়িক জুগাড়ও বড় বিপদ ডাকে'],
    wrong: [
      'ঠিক, একটা সুতো খুলে বেঁধে দিই',
      'আচ্ছা, সাময়িক তো, এতেই চলবে',
      'হ্যাঁ, অ্যালুমিনিয়ামেও কাজ চলে যায়',
      'আচ্ছা, একটা সুতোয় কী আর হবে',
      'হ্যাঁ, মাপামাপির সময় কোথায়',
    ],
    asks: ['কী করবেন?', 'ও বলছে ACSR-এর সুতো বাঁধতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static const coworkerThick = CoworkerScript(
    line: 'গেজ-টেজ লাগবে না, চোখেই বোঝা যায় — মোটাটাই বাঁধো, বারবার উড়বে না!',
    exitLine: coworkerExit,
    right: ['না, মেপে রেটিংয়ের তারই বাঁধব', 'না, মোটা তারে ফিউজ উড়বেই না', 'না, আন্দাজে মোটা তার বাঁধব না'],
    wrong: [
      'ঠিক, মোটাটাই বেঁধে দিই তাহলে',
      'হ্যাঁ, বারবার ওড়ার ঝামেলা কমবে',
      'আচ্ছা, চোখেই তো সব বোঝা যায়',
      'ঠিক আছে, মাপার কোনো দরকার নেই',
      'হ্যাঁ, মোটা তারই বেশি মজবুত',
    ],
    asks: ['কী করবেন?', 'ও বলছে মোটাটাই বাঁধতে। কী করবেন?', 'ওর কথা শুনবেন, না নিয়ম?'],
  );
  static CoworkerScript coworker(M6FusePush p) => switch (p) {
        M6FusePush.acsr => coworkerAcsr,
        M6FusePush.thick => coworkerThick,
      };
  static const allCoworkers = [coworkerAcsr, coworkerThick];

  static String callHeld(M6FusePush p) => switch (p) {
        M6FusePush.acsr => 'ঠিক! ACSR বা জিআই তার কখনও ফিউজের জায়গায় নয়।',
        M6FusePush.thick => 'ঠিক! মোটা নয় — মেপে রেটিংয়ের তার।',
      };

  static const allSet = 'তিনটে ক্যারিয়ারেই মাপা, ঠিক তার — শাবাশ!';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আগে মাপুন, তারপর রেটিং মিলিয়ে বাঁধুন।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন" (SWG named only where the lesson does, ruling X6).
  static String caughtJob(int amps) => switch (amps) {
        16 => '16 A → 0.50 মিমি (প্রায় 25 SWG)',
        32 => '32 A → 0.85 মিমি',
        63 => '63 A → 1.50 মিমি',
        _ => '100 A → 2.00 মিমি (প্রায় 14 SWG)',
      };
  static const caughtMeasured = 'না মেপে একটাও বাঁধেননি';
  static const caughtCall = 'ওর কথায় “না” বলেছেন';

  /// Every new spoken line of the guide (DRAFT — owner wording, then a clip).
  static List<String> get newGuideLines => [
        intro,
        askPlate,
        askMic,
        askTie,
        whyQPlate,
        whyQMic,
        for (final p in M6FusePush.values) callHeld(p),
        'ও বলছে ACSR-এর সুতো বাঁধতে। কী করবেন?',
        'ও বলছে মোটাটাই বাঁধতে। কী করবেন?',
        allSet,
        fail,
        for (final m in M6FuseGaugeMistakes.all) m.textBn,
      ];

  /// The coworker's new pushes (DRAFT — owner wording, then his clip).
  static List<String> get newRivalLines => [coworkerAcsr.line, coworkerThick.line];
}

abstract final class M6FuseGaugeMistakes {
  static const _dir = 'assets/game/art/m6_fuse_gauge';

  // Lesson 6.3 point 5 (index 4): 'চরম অপরাধ' — R12, deadly.
  static const acsr = DoMistake(
    key: '6.3/m6_fuse_gauge/acsr-strand',
    textBn: 'ACSR-এর অ্যালুমিনিয়াম সুতো কিট-ক্যাটে — চরম অপরাধ! এটা ফিউজ তারের চেয়ে অনেক মোটা, ফল্টে গলে না; পুরো ফল্ট কারেন্ট ট্রান্সফরমারে গিয়ে সেটা পুড়ে ছাই হয়।',
    art: '$_dir/jugaad.svg',
    deadly: true,
    lessonPoint: 4,
  );
  static const gi = DoMistake(
    key: '6.3/m6_fuse_gauge/gi-wire',
    textBn: 'জিআই বাইন্ডিং তার কিট-ক্যাটে — চরম অপরাধ! লোহার গলনাঙ্ক অনেক বেশি, ফল্টে গলে না; পুরো ফল্ট কারেন্ট ট্রান্সফরমারে গিয়ে সেটা পুড়ে ছাই হয়।',
    art: '$_dir/jugaad.svg',
    deadly: true,
    lessonPoint: 4,
  );
  // Lesson 6.3 point 4 (index 3): R13, slip.
  static const tooThick = DoMistake(
    key: '6.3/m6_fuse_gauge/too-thick',
    textBn: 'রেটিংয়ের চেয়ে মোটা তার! আন্দাজে মোটা তার লাগালে ফিউজ তারের আসল উদ্দেশ্যই নষ্ট হয়ে যায়। 16 A 0.50, 32 A 0.85, 63 A 1.50, 100 A 2.00 মিমি।',
    art: '$_dir/wrong_size.svg',
    lessonPoint: 3,
  );
  static const tooThin = DoMistake(
    key: '6.3/m6_fuse_gauge/too-thin',
    textBn: 'রেটিংয়ের চেয়ে চিকন তার — এটা এই কাজের তার নয়। 16 A 0.50, 32 A 0.85, 63 A 1.50, 100 A 2.00 মিমি — রেটিং মিলিয়ে বাঁধুন।',
    art: '$_dir/wrong_size.svg',
    lessonPoint: 3,
  );
  static const unmeasured = DoMistake(
    key: '6.3/m6_fuse_gauge/unmeasured',
    textBn: 'না মেপে বাঁধলেন! রিলের গায়ে লেখা নেই — গেজ প্লেট বা মাইক্রোমিটারে ব্যাস মেপে, তবেই বাঁধুন।',
    art: '$_dir/unmeasured.svg',
    lessonPoint: 3,
  );
  // Myth 1's reality (listening to 'মোটাটাই বাঁধো': R13 by B1, a slip).
  static const thickPush = DoMistake(
    key: '6.3/m6_fuse_gauge/thick-push',
    textBn: 'তার অতিরিক্ত মোটা হলে ফিউজ উড়বে না — ট্রান্সফরমার বা ঘরের দামি জিনিস পুড়ে ছাই হবে। মেপে রেটিংয়ের তারই বাঁধুন।',
    art: '$_dir/thick_push.svg',
    lessonPoint: 3,
  );

  /// Listening to a push is the act it pushes (B1).
  static DoMistake push(M6FusePush p) => switch (p) {
        M6FusePush.acsr => acsr,
        M6FusePush.thick => thickPush,
      };

  static const List<DoMistake> all = [acsr, gi, tooThick, tooThin, unmeasured, thickPush];
}

/// One carrier to re-wire.
@immutable
class M6FuseJob {
  const M6FuseJob({required this.place, required this.amps, required this.tool, required this.reels});

  final M6FusePlace place;
  final int amps;
  final M6FuseTool tool;

  /// The four reels on the tray (mm100), in tray order; one is right.
  final List<int> reels;

  int get rightMm => m6RightMm(amps);
}

@immutable
class M6FuseDeal {
  const M6FuseDeal({required this.jobs, required this.coworkerJob, required this.push, required this.acsrLeft});

  /// The three carriers in order: plate, plate, micrometer.
  final List<M6FuseJob> jobs;

  /// The job the coworker comes on, and his push.
  final int coworkerJob;
  final M6FusePush push;

  /// Which side of the plank the ACSR offcut lies on (the GI coil the other).
  final bool acsrLeft;
}

/// The tray for a job: the right reel, one a size thicker and one thinner
/// (where the plate has them), and one far off; shuffled.
List<int> m6DealReels(int right, math.Random rng) {
  final i = m6PlateMm.indexOf(right);
  final picks = <int>[right, if (i + 1 < m6PlateMm.length) m6PlateMm[i + 1], if (i > 0) m6PlateMm[i - 1]];
  final far = [
    for (var k = 0; k < m6PlateMm.length; k++)
      if ((k - i).abs() >= 2) m6PlateMm[k],
  ]..shuffle(rng);
  for (final f in far) {
    if (picks.length == 4) break;
    picks.add(f);
  }
  return picks..shuffle(rng);
}

M6FuseDeal m6FuseDeal(math.Random rng) {
  final places = [...M6FusePlace.values]..shuffle(rng);
  List<int> amps;
  do {
    amps = [for (final p in places) m6PlaceAmps[p]![rng.nextInt(2)]];
  } while (amps.toSet().length < 3);
  final jobs = [
    for (var i = 0; i < 3; i++)
      M6FuseJob(place: places[i], amps: amps[i], tool: i == 2 ? M6FuseTool.micrometer : M6FuseTool.plate, reels: m6DealReels(m6RightMm(amps[i]), rng)),
  ];
  final push = rng.nextBool() ? M6FusePush.acsr : M6FusePush.thick;
  // 'মোটাটাই বাঁধো' on job 2 or 3 (spec); the ACSR push on any job.
  final at = push == M6FusePush.acsr ? rng.nextInt(3) : 1 + rng.nextInt(2);
  return M6FuseDeal(jobs: jobs, coworkerJob: at, push: push, acsrLeft: rng.nextBool());
}

/// The play state (pure logic).
class M6FuseRun {
  M6FuseRun(this.deal);
  final M6FuseDeal deal;

  int index = 0;
  int slips = 0;
  int jobSlips = 0;
  DoMistake? deadly;
  final List<String> caught = [];
  var _unmeasuredEver = false;

  /// The job's wire is tied right (its reason comes next).
  var roundDone = false;

  /// A wire was taken up on this job (the coworker's gate).
  var loaded = false;

  /// His chalk number under each reel he measured snug (mm100).
  final Map<int, int> chalk = {};
  int probes = 0;

  /// The wire on the top screw; tied to the bottom screw.
  int? anchored;
  var fitted = false;

  /// The micrometer (the third job): the wire in its jaws, its reading.
  int? micLoaded;
  int? micReading;

  M6FuseJob get job => deal.jobs[index.clamp(0, 2)];
  bool get done => index >= 3;
  bool get ended => done || deadly != null;
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;
  bool get thorough => jobSlips == 0;
  bool get _open => !ended && !roundDone;

  /// A source's real diameter (mm100).
  int mmOf(int src) => src < 4 ? job.reels[src] : (src == m6AcsrSrc ? m6AcsrMm : m6GiMm);

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  DoMistake _slip(DoMistake m) {
    slips++;
    jobSlips++;
    return m;
  }

  /// A wire taken up from the bench.
  void take(int src) {
    if (_open) loaded = true;
  }

  /// The wire [src] pushed into plate slot [slot]; snug writes his chalk.
  M6Fit? probe(int src, int slot) {
    if (!_open || job.tool != M6FuseTool.plate) return null;
    loaded = true;
    probes++;
    final mm = mmOf(src);
    final s = m6PlateMm[slot];
    if (mm > s) return M6Fit.narrow;
    if (mm < s) return M6Fit.loose;
    if (src < 4) chalk[src] = s;
    return M6Fit.snug;
  }

  /// The wire [src] in the micrometer's jaws (the micrometer job only).
  bool micLoad(int src) {
    if (!_open || job.tool != M6FuseTool.micrometer) return false;
    loaded = true;
    micLoaded = src;
    micReading = null;
    return true;
  }

  /// The thimble rolled to the ratchet click: the mm reading (a reel's goes
  /// down in chalk).
  int? micSpin() {
    final m = micLoaded;
    if (!_open || m == null) return null;
    probes++;
    final mm = micReading = mmOf(m);
    if (m < 4) chalk[m] = mm;
    return mm;
  }

  /// The wire [src] hooked on the carrier's top screw.
  void anchor(int src) {
    if (!_open) return;
    loaded = true;
    anchored = src;
  }

  /// Tied down to the bottom screw: ACSR / GI = deadly (R12); a reel never
  /// measured snug = slip; a wrong diameter = slip (R13); right = done.
  DoMistake? tie() {
    final a = anchored;
    if (!_open || a == null) return null;
    if (a == m6AcsrSrc || a == m6GiSrc) {
      fitted = true;
      return deadly = a == m6AcsrSrc ? M6FuseGaugeMistakes.acsr : M6FuseGaugeMistakes.gi;
    }
    if (!chalk.containsKey(a)) {
      anchored = null;
      _unmeasuredEver = true;
      return _slip(M6FuseGaugeMistakes.unmeasured);
    }
    final mm = job.reels[a];
    if (mm != job.rightMm) {
      anchored = null;
      return _slip(mm > job.rightMm ? M6FuseGaugeMistakes.tooThick : M6FuseGaugeMistakes.tooThin);
    }
    fitted = true;
    roundDone = true;
    _tag(M6FuseGaugeLines.caughtJob(job.amps));
    if (index == 2 && !_unmeasuredEver) _tag(M6FuseGaugeLines.caughtMeasured);
    return null;
  }

  /// Listened to the slip-line coworker.
  DoMistake pushSlip(DoMistake m) => _slip(m);

  /// Fails the play (listening to the deadly push).
  void failDeadly(DoMistake m) => deadly = m;

  void next() {
    index++;
    jobSlips = 0;
    roundDone = false;
    loaded = false;
    chalk.clear();
    probes = 0;
    anchored = null;
    fitted = false;
    micLoaded = null;
    micReading = null;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded).
/// ms, ~1500 per human action:
///   plate job: take, 3 probes, anchor, tie ≈ 9000 + reason ~8000
///   plate job again                        ≈ 17000
///   micrometer job: 3 × (load + roll), anchor, tie ≈ 12000 + reason ~8000
/// + the coworker once ≈ 9600                              ≈ 71600
/// 85 % ≈ 61000 → 60 s. (A new level's quickMs: owner to confirm.)
const m6FuseGaugeQuickMs = 60000;

@immutable
class M6FuseGaugePack {
  const M6FuseGaugePack({required this.id, required this.titleBn, this.quickMs = m6FuseGaugeQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const Map<String, M6FuseGaugePack> m6FuseGaugePacks = {
  'do_6_3_a': M6FuseGaugePack(id: 'do_6_3_a', titleBn: M6FuseGaugeLines.title),
};

// ============================================================================
// Page
// ============================================================================

class M6FuseGaugePage extends StatefulWidget {
  const M6FuseGaugePage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final M6FuseGaugePack pack;
  final bool muted;
  final int? seed;

  @override
  State<M6FuseGaugePage> createState() => _M6FuseGaugePageState();
}

class _M6FuseGaugePageState extends State<M6FuseGaugePage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _FuseRunPage(
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

class _FuseRunPage extends ConsumerStatefulWidget {
  const _FuseRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final M6FuseGaugePack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_FuseRunPage> createState() => _FuseRunPageState();
}

class _FuseRunPageState extends ConsumerState<_FuseRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final M6FuseRun _run;
  late final int _seed = _run.deal.coworkerJob * 7 + _run.deal.push.index;
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

  /// The wire in hand.
  int? _held;

  /// The last probe's result by its slot.
  ({int slot, M6Fit fit})? _chip;
  int _chipTok = 0;
  Timer? _chipTimer;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  /// The gesture hand (how to touch, never what).
  final _hints = IdleHintController();
  int _hintN = 0;
  int _steps = 0;
  M6FuseGeo? _geoNow;

  // A drag on the scene.
  Offset? _dragFrom;
  Offset _dragNow = Offset.zero;
  Offset _dragGlobal = Offset.zero;
  int? _dragSrc;

  @override
  void initState() {
    super.initState();
    _run = M6FuseRun(m6FuseDeal(widget.rng));
  }

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);

  @override
  void dispose() {
    disposeCoworker();
    _chipTimer?.cancel();
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

  M6FuseJob get _job => _run.job;
  bool get _acsrLeft => _run.deal.acsrLeft;

  bool get _canPlay =>
      !_intro && !_ended && _card == null && !reasonOpen && !tableBusy && !coworkerOpen && !_run.roundDone && !_freeze;

  String get _task {
    if (_run.anchored != null) return M6FuseGaugeLines.askTie;
    return _job.tool == M6FuseTool.micrometer ? M6FuseGaugeLines.askMic : M6FuseGaugeLines.askPlate;
  }

  Future<void> _start() async {
    _clock.start();
    _startJob();
  }

  void _startJob() {
    setState(() {
      _wake++;
      _held = null;
      _chip = null;
    });
    unawaited(_sayChain([_task]));
  }

  /// On his job, once he is due, every measuring or tying control waits.
  bool _waitForHim() => _run.index == _run.deal.coworkerJob && holdForCoworker();

  void _maybeSchedule() {
    if (coworkerDone || coworkerDue || _run.index != _run.deal.coworkerJob) return;
    if (_run.loaded) scheduleCoworker();
  }

  void _tick([String file = 'sounds/intro/tick.ogg', double volume = 0.45]) {
    HapticFeedback.selectionClick();
    _cue(file, volume: volume);
  }

  void _stepDone() {
    _steps++;
    _maybeSchedule();
    setState(() => _wake++);
  }

  int? _sourceAt(Offset p, M6FuseGeo geo) {
    for (var s = 0; s < m6SourceCount; s++) {
      if (geo.sourceHit(s, acsrLeft: _acsrLeft).contains(p)) return s;
    }
    return null;
  }

  int? _slotAt(Offset p, M6FuseGeo geo) {
    if (_job.tool != M6FuseTool.plate) return null;
    for (var k = 0; k < m6PlateMm.length; k++) {
      if (geo.slotHit(k).inflate(3).contains(p)) return k;
    }
    return null;
  }

  // --- hands on -----------------------------------------------------------------
  void _takeUp(int src) {
    _tick('sounds/intro/click.ogg', 0.5);
    _run.take(src);
    setState(() {
      _held = src;
      _wake++;
    });
    _maybeSchedule();
  }

  void _probe(int src, int slot) {
    if (_waitForHim()) return;
    final f = _run.probe(src, slot);
    if (f == null) return;
    switch (f) {
      case M6Fit.narrow:
        HapticFeedback.lightImpact();
        _cue('sounds/intro/tick.ogg', volume: 0.4);
      case M6Fit.loose:
        HapticFeedback.selectionClick();
        _cue('sounds/learn/ring_steel.ogg', volume: 0.35);
      case M6Fit.snug:
        HapticFeedback.mediumImpact();
        _cue('sounds/intro/impact_metal.ogg', volume: 0.5);
    }
    _chipTimer?.cancel();
    setState(() {
      _held = src;
      _chip = (slot: slot, fit: f);
      _chipTok++;
    });
    _chipTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _chip = null);
    });
    _stepDone();
  }

  void _micLoad(int src) {
    if (_waitForHim()) return;
    if (!_run.micLoad(src)) return;
    _tick('sounds/intro/click.ogg', 0.5);
    setState(() => _held = null);
    _stepDone();
  }

  void _micSpin() {
    if (_run.micLoaded == null) {
      _hints.missTap();
      return;
    }
    if (_waitForHim()) return;
    if (_run.micSpin() == null) return;
    HapticFeedback.mediumImpact();
    _cue('sounds/intro/tick.ogg', volume: 0.6);
    _stepDone();
  }

  void _anchor(int src) {
    if (_waitForHim()) return;
    _run.anchor(src);
    _tick('sounds/learn/ring_steel.ogg', 0.5);
    setState(() => _held = null);
    _stepDone();
    unawaited(_sayChain([M6FuseGaugeLines.askTie]));
  }

  void _tie(Offset global) {
    if (_waitForHim()) return;
    final a = _run.anchored;
    final m = _run.tie();
    if (m != null) {
      setState(() => _wake++);
      unawaited(_mistake(m, global));
      return;
    }
    if (a == null || !_run.roundDone) return;
    unawaited(_jobDone());
  }

  void _tapScene(Offset p, M6FuseGeo geo, Offset global) {
    if (!_canPlay) return;
    final src = _sourceAt(p, geo);
    if (src != null) {
      if (_held == src) {
        setState(() => _held = null);
        _tick();
        return;
      }
      _takeUp(src);
      return;
    }
    final held = _held;
    final slot = _slotAt(p, geo);
    if (slot != null && held != null) {
      _probe(held, slot);
      return;
    }
    if (_job.tool == M6FuseTool.micrometer && geo.jawsHit.contains(p) && held != null) {
      _micLoad(held);
      return;
    }
    if (geo.topScrewHit.contains(p) && held != null) {
      _anchor(held);
      return;
    }
    if (geo.bottomScrewHit.contains(p) && _run.anchored != null) {
      _tie(global);
      return;
    }
    // The thimble rolls with a drag; any other spot is nothing.
    _hints.missTap();
  }

  void _panStart(Offset p, M6FuseGeo geo) {
    if (!_canPlay) return;
    _dragFrom = p;
    _dragNow = p;
    final src = _sourceAt(p, geo);
    if (src != null) {
      _dragSrc = src;
      if (_held != src) _takeUp(src);
    }
  }

  void _panUpdate(Offset p, Offset global) {
    _dragNow = p;
    _dragGlobal = global;
    if (_dragSrc != null) setState(() {});
  }

  void _panEnd(M6FuseGeo geo) {
    final global = _dragGlobal;
    final from = _dragFrom;
    final src = _dragSrc;
    _dragFrom = null;
    _dragSrc = null;
    if (from == null || !_canPlay) {
      if (src != null && mounted) setState(() {});
      return;
    }
    final to = _dragNow;
    if (src != null) {
      setState(() {});
      final slot = _slotAt(to, geo);
      if (slot != null) {
        _probe(src, slot);
        return;
      }
      if (_job.tool == M6FuseTool.micrometer && geo.jawsHit.inflate(6).contains(to)) {
        _micLoad(src);
        return;
      }
      if (geo.topScrewHit.inflate(6).contains(to)) {
        _anchor(src);
        return;
      }
      // Dropped anywhere else: the wire stays in hand.
      return;
    }
    final d = to - from;
    if (_job.tool == M6FuseTool.micrometer && geo.thimbleHit.inflate(6).contains(from) && d.distance >= 40) {
      _micSpin();
      return;
    }
    if (_run.anchored != null && geo.topScrewHit.inflate(6).contains(from) && d.dy >= 50) {
      _tie(global);
      return;
    }
    _hints.missTap();
  }

  Future<void> _jobDone() async {
    _hush();
    HapticFeedback.mediumImpact();
    _cue('sounds/learn/tag_slap.ogg', volume: 0.7);
    setState(() {
      _held = null;
      _chip = null;
      _wake++;
    });
    putOnTable(15 + (_run.thorough ? 5 : 0));
    final job = _job;
    final idx = _run.index;
    final mic = job.tool == M6FuseTool.micrometer;
    unawaited(askReason(
      deal: () => mic
          ? dealChoices(M6FuseGaugeLines.whyMicRight(job.amps), M6FuseGaugeLines.whyMicWrong(job.amps), widget.rng)
          : dealChoices(M6FuseGaugeLines.whyRule, M6FuseGaugeLines.myths, widget.rng),
      question: mic ? M6FuseGaugeLines.whyQMic : M6FuseGaugeLines.whyQPlate,
      stillValid: () => _run.index == idx && !_ended,
    ));
  }

  void _next() {
    setState(_run.next);
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startJob();
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
  CoworkerScript get coworkerScript => M6FuseGaugeLines.coworker(_run.deal.push);
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.coworkerJob || _run.roundDone) return null;
    if (_intro || _card != null || tableBusy || _freeze) return false;
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
      final m = M6FuseGaugeMistakes.push(p);
      if (m.deadly) {
        _run.failDeadly(m);
        await _deadly(m);
        return;
      }
      _run.pushSlip(m);
      unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
      await _slip(m);
      return;
    }
    _run.caught.add(M6FuseGaugeLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _ended) return;
    unawaited(_sayChain([M6FuseGaugeLines.callHeld(p), _task], mood: GuideMood.glad));
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? M6FuseGaugeLines.tapWhy[_nudgeN++ % M6FuseGaugeLines.tapWhy.length]
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
      _held = null;
      _wake++;
    });
    unawaited(bookMistake(ref, widget.ctx, m));
    final speak = await SpokenOnce.first('m6fuse/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// A jugaad wire in the fuse's place: the scene freezes grey and the
  /// transformer's fire comes off it in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _clock.stop();
    _hush();
    _chipTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/spark.ogg', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _held = null;
      _chip = null;
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
    final speak = await SpokenOnce.first('m6fuse/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? M6FuseGaugeLines.deadlyWord : M6FuseGaugeLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        // The same job goes on from where it was.
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
    await _say(!_run.passed ? M6FuseGaugeLines.fail : (_quickBonus ? M6FuseGaugeLines.quick : M6FuseGaugeLines.allSet),
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
    if (_held != null) return LinemanMode.hold;
    return LinemanMode.idle;
  }

  M6FuseRig get _rig => M6FuseRig(
        place: _job.place,
        tool: _job.tool,
        acsrLeft: _acsrLeft,
        chalk: {..._run.chalk},
        held: _held,
        anchored: _run.anchored,
        fitted: _run.fitted,
        micLoaded: _run.micLoaded,
        micReading: _run.micReading,
      );

  List<Rect> _sourceRects(M6FuseGeo geo) => [for (var s = 0; s < m6SourceCount; s++) geo.sourceHit(s, acsrLeft: _acsrLeft)];

  /// The gesture hand: how to touch, never what. A wire on the top screw: a
  /// short drag down from it. The micrometer loaded: a swipe along the
  /// thimble. A wire in hand: a drag nudge toward the plate's (or the
  /// micrometer's) centre — never a slot — or, after a probe, a sweep over
  /// the slots, the tray and the carrier. Nothing in hand: a sweep over every
  /// wire alike (with the tool), or over the tray and the carrier once a reel
  /// has its chalk.
  HintSpec? _hint() {
    final geo = _geoNow;
    if (geo == null) return null;
    final n = _hintN++;
    final mic = _job.tool == M6FuseTool.micrometer;
    if (_run.anchored != null) return HintSpec.drag(geo.topScrew, toward: const Offset(0, 1), travel: 60, space: HintSpace.scene);
    if (mic && _run.micLoaded != null && _run.micReading == null) {
      return HintSpec.swipe(geo.thimbleHit.bottomCenter.translate(0, -8), toward: const Offset(0, -1), travel: 44, space: HintSpace.scene);
    }
    final held = _held;
    final sources = _sourceRects(geo);
    final carrier = [geo.topScrewHit, geo.bottomScrewHit];
    if (held != null) {
      final from = geo.source(held, acsrLeft: _acsrLeft);
      final hub = mic ? geo.jawsHit.center.translate(40, 0) : geo.plate;
      if (n.isEven || _run.probes == 0) {
        final d = hub - from;
        return HintSpec.drag(from, toward: d / math.max(1.0, d.distance), travel: math.min(80.0, d.distance * 0.6), space: HintSpace.scene);
      }
      return HintSpec.sweep([if (!mic) for (var k = 0; k < m6PlateMm.length; k++) geo.slotHit(k), ...sources, ...carrier], space: HintSpace.scene);
    }
    if (n.isOdd && _run.chalk.isNotEmpty) return HintSpec.sweep([...sources, ...carrier], space: HintSpace.scene);
    return HintSpec.sweep([...sources, if (mic) geo.jawsHit else geo.plateHit], space: HintSpace.scene);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = _geoNow = M6FuseGeo.forScene(m.height, m.inset);
    final quiet = _quiet;
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final chip = _chip;
    final dragSrc = _dragSrc;
    final job = _job;
    return [
      Positioned.fill(
        key: const ValueKey('world'),
        child: ColorFiltered(
          colorFilter: grey,
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('bench'),
                child: RepaintBoundary(child: CustomPaint(painter: M6FusePainter(geo: geo, rig: _rig, seed: _seed + _run.index))),
              ),
              Positioned.fromRect(
                key: const ValueKey('trainee'),
                rect: geo.trainee,
                child: LinemanFigure(look: _gloved, mode: _mode, wake: _wake, quiet: quiet),
              ),
            ],
          ),
        ),
      ),
      // The job docket (place and amps; never the wire size).
      Positioned.fromRect(
        key: ValueKey('docket-${_run.index}'),
        rect: M6FuseGeo.docket,
        child: IgnorePointer(
          child: ColorFiltered(colorFilter: grey, child: _Docket(place: job.place, amps: job.amps)),
        ),
      ),
      if (dragSrc != null && !_freeze)
        Positioned.fill(
          key: const ValueKey('drag-wire'),
          child: IgnorePointer(child: CustomPaint(painter: M6DragWirePainter(from: geo.source(dragSrc, acsrLeft: _acsrLeft), to: _dragNow))),
        ),
      if (chip != null && !_freeze)
        Positioned(
          key: ValueKey('fit-$_chipTok'),
          left: (geo.slot(chip.slot).dx - 34).clamp(2.0, 300.0),
          top: geo.slot(chip.slot).dy + (chip.slot == 0 ? -40 : 16),
          child: IgnorePointer(child: _FitChip(fit: chip.fit)),
        ),
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: M6FuseGaugeLines.sceneLabel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tapScene(d.localPosition, geo, d.globalPosition),
            onPanStart: (d) => _panStart(d.localPosition, geo),
            onPanUpdate: (d) => _panUpdate(d.localPosition, d.globalPosition),
            onPanEnd: (_) => _panEnd(geo),
          ),
        ),
      ),
      // Screen-reader handles on the scene's targets (invisible).
      for (var s = 0; s < m6SourceCount; s++) _sem('src-$s', geo.sourceHit(s, acsrLeft: _acsrLeft), M6FuseGaugeLines.source(s)),
      if (job.tool == M6FuseTool.plate)
        for (var k = 0; k < m6PlateMm.length; k++) _sem('slot-$k', geo.slotHit(k), M6FuseGaugeLines.slot(k)),
      if (job.tool == M6FuseTool.micrometer) ...[
        _sem('jaws', geo.jawsHit, M6FuseGaugeLines.jaws),
        _sem('thimble', geo.thimbleHit, M6FuseGaugeLines.thimble),
      ],
      _sem('top-screw', geo.topScrewHit, M6FuseGaugeLines.topScrew),
      _sem('bottom-screw', geo.bottomScrewHit, M6FuseGaugeLines.bottomScrew),
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('fire'),
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: quiet ? 1 : 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (_, v, _) => CustomPaint(painter: M6FuseFirePainter(at: M6FuseGeo.dtrTank.center, v: v)),
            ),
          ),
        ),
      // The next carrier: a short fade.
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

  /// An invisible label over a painted target (screen readers, tests); the
  /// touch goes through to the scene's own detector.
  Widget _sem(String key, Rect r, String label) => Positioned.fromRect(
        key: ValueKey('sem-$key'),
        rect: r,
        child: IgnorePointer(child: Semantics(label: label, excludeSemantics: true, child: const SizedBox.expand())),
      );

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.roundDone && !deckUp && !coworkerOpen && _card == null;
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
              labels: [for (final j in _run.deal.jobs) M6FuseGaugeLines.carrier(j.amps)],
              done: {for (var i = 0; i < math.min(_run.index, 3); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            layers: (context, m) => _scene(m),
            hint: _hint,
            hintWaiting: handsOn && !tableBusy,
            hintKey: '${_run.index}/$_steps/$_held/${_run.anchored}',
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
                    child: reasonOpen
                        ? reasonDeck(quiet: quiet, key: const ValueKey('why-deck'))
                        : coworkerDeck(quiet: quiet, key: const ValueKey('choice-deck')),
                  ),
                ),
              if (playing && _card == null) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 8), onLeft: coworkerFromRight),
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
                  line: M6FuseGaugeLines.intro,
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

  /// The trainee in insulated gloves (and goggles by the lesson's PPE rule —
  /// not drawn at this size).
  static const _gloved = LinemanLook(
    helmet: Color(0xFFFFD34E),
    shirt: Color(0xFF1F5F8F),
    vest: Color(0xFFFF851B),
    pants: Color(0xFF26303D),
    skin: Color(0xFFA86E48),
    gloves: true,
    gloveColor: LinemanLook.rubberGloves,
  );
}

// ============================================================================
// Pieces
// ============================================================================

/// The job docket: the place, its isolation stamp and the carrier's amps.
class _Docket extends StatelessWidget {
  const _Docket({required this.place, required this.amps});
  final M6FusePlace place;
  final int amps;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1DE),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8A6A3C), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Text(M6FuseGaugeLines.docketHead, style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF7A5A2E))),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(M6FuseGaugeLines.isolation(place), style: bangla(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF1E7A3A))),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(M6FuseGaugeLines.place(place), style: bangla(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF2A2018))),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(M6FuseGaugeLines.carrier(amps), style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1C2E4A))),
            ),
          ],
        ),
      ),
    );
  }
}

/// How the wire sat in the slot.
class _FitChip extends StatelessWidget {
  const _FitChip({required this.fit});
  final M6Fit fit;

  @override
  Widget build(BuildContext context) {
    final icon = switch (fit) {
      M6Fit.narrow => Icons.block_rounded,
      M6Fit.loose => Icons.swap_horiz_rounded,
      M6Fit.snug => Icons.check_circle_rounded,
    };
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xEE101A2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6E7C90), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: SlmColors.gold300),
          const SizedBox(width: 3),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(M6FuseGaugeLines.fit(fit), style: bangla(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
