import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
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
import 'scene_kit.dart' show AwakeClock, Carry, GuideIntro, LinemanFigure, LinemanLook, LinemanMode;
import 'sky_world.dart';
import 'spoken_once.dart';

export 'sky_world.dart' show SkyBolt;

// Lesson 1.9 "ঝড়-বৃষ্টিতে কাজ: কখন 'না' বলবেন", কাজ 1 "আকাশ পড়ুন"
// (ladder step 26). The trainee is up an 11 kV PCC pole on a job; four
// moments a play (four jobs), and at each one the weather turns: drizzle, a
// strong wind with the conductors galloping, a flash far on the horizon, a
// near strike. Hands on: read the sky — tap the sign in the scene (the wet
// pole, the galloping wires and bent trees, the lightning), check the weather
// on the phone (wind km/h, rain: lesson pro tip 1), put on the waterproof
// gloves — then say what to do: কাজ চালাই, or কাজ বন্ধ — নেমে আসি.
//
// The lesson's rules, and only those:
//   • rain (point 1): general maintenance stops in the rain; only an emergency
//     fault repair goes on, with the utmost care and waterproof gloves; when
//     thunder starts, stop at once;
//   • lightning (point 2): seen or heard → stop work at height and go to a
//     safe shelter; no PPE helps — the red line;
//   • wind (point 3): above about 40–50 km/h stop work at height; in doubt,
//     stop (so 45 km/h is a stop).
// The docket on the scene says which job it is (সাধারণ রক্ষণাবেক্ষণ or জরুরি
// ফল্ট মেরামত).
//
// Deadly (owner-approved ladder row): staying on the pole in lightning (also
// by listening to the coworker). Slips: working on in a strong wind, working
// on at general maintenance in the rain, an emergency repair in the rain
// without the waterproof gloves, working on without checking the weather.
// Three slips strike the level out.
// Stopping where the lesson lets the work go on (a calm sky, an emergency
// repair in a drizzle) is NOT scored — Stop Work is the worker's right (pro
// tip 3; the wind rule: in doubt, stop) — the guide says the lesson's rule and
// the moment stays, so always stopping cannot move the play on. Scoring it
// would be a new scoring event: an owner decision (GAME_LEVEL_PLAYBOOK §6).
//
// Tapping the scene gives every tap the same plain mark (no tell before the
// decision); which taps were real signs shows only once the reason is paid.
//
// Built on the shared level kit (GAME_LEVEL_PLAYBOOK.md): guide first, full
// scene (sky_world.dart), corner guide, ◆ on the table → "কেন …?" (the reasons
// fit this moment's weather) → the next job by itself; the careless coworker
// once a play, on a moment where the work must stop: "আর একটু, শেষ করে নামি!"
// (his recorded voice).
// Voice: the guide's lines by device TTS; the coworker in his recorded voice.
// Sounds: thunder and the gust are synthesised by tool/make_sky_sfx.py.

// ============================================================================
// Content
// ============================================================================

/// What the weather does at a moment.
enum SkyKind { calm, rainJob, rainUrgent, wind, boltFar, boltNear }

/// The job on the docket.
enum SkyJob { maintenance, emergency }

/// A sign the player can spot in the scene.
enum SkySign { wet, wind, bolt }

/// Why the work must stop (the strongest first).
enum SkyHazard { bolt, wind, rainJob }

/// The hands-on checks.
enum SkyCheck { phone, gloves }

@immutable
class SkyCase {
  const SkyCase({required this.id, required this.kind, required this.job, required this.windKmh});
  final String id;
  final SkyKind kind;
  final SkyJob job;

  /// What the phone's weather reads (km/h).
  final int windKmh;

  bool get drizzle => kind == SkyKind.rainJob || kind == SkyKind.rainUrgent || kind == SkyKind.boltNear;
  SkyBolt get bolt => switch (kind) {
        SkyKind.boltFar => SkyBolt.far,
        SkyKind.boltNear => SkyBolt.near,
        _ => SkyBolt.none,
      };

  /// Lesson point 3: above about 40–50 km/h (in doubt, stop).
  bool get windy => windKmh >= 40;

  SkyHazard? get hazard {
    if (bolt != SkyBolt.none) return SkyHazard.bolt;
    if (windy) return SkyHazard.wind;
    if (drizzle && job == SkyJob.maintenance) return SkyHazard.rainJob;
    return null;
  }

  bool get mustStop => hazard != null;

  /// Work goes on in the rain only for an emergency repair, with waterproof gloves.
  bool get needsGloves => !mustStop && drizzle;

  /// The signs in the scene.
  Set<SkySign> get signs => {
        if (drizzle) SkySign.wet,
        if (windy) SkySign.wind,
        if (bolt != SkyBolt.none) SkySign.bolt,
      };

  SkyWeather get weather => switch (kind) {
        SkyKind.calm => SkyWeather(cloud: 0.35, dark: 0.06, wind: windKmh.toDouble()),
        SkyKind.rainJob || SkyKind.rainUrgent => SkyWeather(cloud: 0.85, dark: 0.42, rain: 0.6, wind: windKmh.toDouble()),
        SkyKind.wind => SkyWeather(cloud: 0.6, dark: 0.26, wind: windKmh.toDouble()),
        SkyKind.boltFar => SkyWeather(cloud: 0.45, dark: 0.2, wind: windKmh.toDouble(), bolt: SkyBolt.far),
        SkyKind.boltNear => SkyWeather(cloud: 1, dark: 0.72, rain: 0.65, wind: windKmh.toDouble(), bolt: SkyBolt.near),
      };
}

abstract final class SkyLines {
  /// What the guide repeats (a different way each time) when tapped.
  static const tasks = [ask];

  static const title = 'আকাশ পড়ুন';
  static const intro = 'আকাশ বদলাচ্ছে, আপনি পোলের ওপরে! মেঘ, বাতাস, বজ্র পড়ুন — ঠিক সময়ে থামুন।';
  static const rounds = ['ক', 'খ', 'গ', 'ঘ'];
  static const ask = 'আকাশ পড়ুন। কাজ চালাবেন, না থামবেন?';
  static const tapWhy = ['কারণটা বেছে নিন।', 'ঠিক কারণটা কোনটা?'];

  // Labels a worker reads (buttons, the docket, the phone).
  static const sceneLabel = 'আকাশ আর পোল';
  static const phone = 'আবহাওয়া';
  static const gloves = 'ওয়াটারপ্রুফ গ্লাভস';
  static const stop = 'কাজ বন্ধ — নেমে আসি';
  static const go = 'কাজ চালাই';
  static const docket = 'ডকেট';
  static const jobMaintenance = 'সাধারণ রক্ষণাবেক্ষণ';
  static const jobEmergency = 'জরুরি ফল্ট মেরামত';
  static String jobBn(SkyJob j) => j == SkyJob.maintenance ? jobMaintenance : jobEmergency;
  static const phoneWind = 'বাতাস';
  static const phoneRain = 'বৃষ্টি';
  static const rainNone = 'নেই';
  static const rainLight = 'হালকা';
  static const phoneClose = 'বন্ধ';
  static String kmh(int v) => enDigits('$v km/h');

  // What the thunder sounds like (the sound only, never its meaning).
  static const rumble = 'গুড়ুম গুড়ুম';
  static const crack = 'কড়াৎ!';

  static const stampStop = 'নেমে এলাম';
  static const stampGo = 'কাজ চলছে';

  // The reasons (lesson 1.9): the right ones fit this moment's weather; the
  // wrong ones are false claims and bad motives (to stop) or the lesson's
  // myths and field excuses (to work on) — never a true rule marked wrong.
  // Every card 36–43 letters, so none stands out by its length.
  static const whyStop = 'কেন থামলেন?';
  static const whyGo = 'কেন চালিয়ে গেলেন?';
  static const rainJobWhy = ['সাধারণ রক্ষণাবেক্ষণ বৃষ্টিতে বন্ধ রাখতে হয়', 'বৃষ্টিতে শুধু জরুরি মেরামত, এটা সাধারণ কাজ'];
  static const wetWhy = ['ভেজা পোল আর ক্রস-আর্ম পিছল, পড়ার ঝুঁকি', 'ভেজা আবহাওয়ায় আর্ক ফ্ল্যাশের ঝুঁকি বাড়ে'];
  static const windWhy = ['বাতাস 40–50 km/h ছাড়ালে উঁচুতে কাজ বন্ধ', 'তার দুলছে, ফেজে ফেজে শর্ট হয়ে যেতে পারে', 'জোর বাতাসে পোলের ওপর ভারসাম্য রাখা কঠিন'];
  static const boltWhy = ['বজ্র দেখলে বা শুনলেই উঁচুতে কাজ বন্ধ', 'বজ্রে কোনো পিপিই কাজ করে না, এটা রেড লাইন'];
  static const boltFarWhy = 'দূরে হলেও বজ্র দেখা গেছে, তাই কাজ বন্ধ';
  static const boltNearWhy = 'কাছে বজ্র পড়লে মাটি-লাইন দিয়েও শক আসে';
  static const goCalmWhy = ['বাতাস কম, বৃষ্টি বা বজ্রের কোনো চিহ্ন নেই', 'আবহাওয়া দেখে নিয়েছি, কাজ চালানোর মতো'];
  static const goRainWhy = ['জরুরি ফল্ট মেরামত, ওয়াটারপ্রুফ গ্লাভস পরা', 'বৃষ্টিতে জরুরি মেরামত চলে, খুব সাবধানে'];

  /// Wrong reasons to work on (the lesson's myths and field excuses).
  static const goMyths = [
    'রাবারের জুতো-গ্লাভস আছে, বজ্রে কিছু হবে না',
    'সুপারভাইজার চাপ দিচ্ছেন, শেষ করতেই হবে',
    'আকাশ দেখার দরকার নেই, কাজটাই আসল কথা',
    'একটু বৃষ্টি-বাতাসে লাইনম্যান ভয় পায় না',
    'কাজ অর্ধেক হয়ে গেছে, এখন থামা যায় না',
    'সবাই তো এমন আবহাওয়াতেই কাজ করে যায়',
  ];

  /// Wrong reasons to stop: a false claim (the lesson: no PPE helps in
  /// lightning; general maintenance stops in the rain whatever the gloves)
  /// and the bad motives a field worker might have — none is a lesson rule.
  static const stopExcuses = [
    'গ্লাভস আনিনি, নইলে এতেও কাজ চালানো যেত',
    'ভিজে গেলে জামা-জুতো নষ্ট হবে, তাই নামলাম',
    'সুপারভাইজার দেখছেন না, একটু জিরিয়ে নিই',
    'চা খাওয়ার সময় হয়ে গেছে, তাই নেমে এলাম',
    'কাজ ঝুলিয়ে রাখলে ওভারটাইম বেশি পাব',
    'আজকের কাজটা কঠিন, পরে অন্য কেউ করে দেবে',
  ];

  static const allBoltWhy = [...boltWhy, boltFarWhy, boltNearWhy];

  /// The right reasons for what [c] had.
  static List<String> whyRight(SkyCase c) => switch (c.hazard) {
        SkyHazard.bolt => [...boltWhy, c.bolt == SkyBolt.far ? boltFarWhy : boltNearWhy],
        SkyHazard.wind => windWhy,
        SkyHazard.rainJob => [...rainJobWhy, ...wetWhy],
        null => c.drizzle ? goRainWhy : goCalmWhy,
      };

  /// The wrong cards for [c]'s deck: a stop, the false claims and bad
  /// motives; working on, the myths and excuses.
  static List<String> whyWrong(SkyCase c) => c.mustStop ? stopExcuses : goMyths;

  /// A stop where the lesson lets the work go on: not scored (Stop Work is
  /// the worker's right, pro tip 3); the guide says the lesson's rule and
  /// the moment stays.
  static const needlessCalm = 'থামা আপনার অধিকার। তবে বাতাস কম, বৃষ্টি বা বজ্র নেই — এখানে কাজ চলে।';
  static const needlessUrgent = 'থামা আপনার অধিকার। তবে বৃষ্টিতে জরুরি ফল্ট মেরামত চলে — ওয়াটারপ্রুফ গ্লাভস পরে, খুব সাবধানে।';
  static String needless(SkyCase c) => c.drizzle ? needlessUrgent : needlessCalm;

  /// The careless coworker (his recorded voice): finish first.
  static const coworkerExit = 'হুঁ! যা খুশি করুন।';
  static const coworker = CoworkerScript(
    line: 'আর একটু, শেষ করে নামি! এইটুকু কাজ ফেলে কেউ নামে?',
    exitLine: coworkerExit,
    right: ['না, এখনই কাজ থামিয়ে নেমে আসছি', 'না, আকাশ যা বলছে সেটাই শুনব', 'কাজের চেয়ে জীবন বড়, এখনই নামছি'],
    wrong: ['ঠিক, আর একটু করে তবেই নামি', 'আচ্ছা, তাড়াতাড়ি শেষ করে ফেলি', 'এইটুকু কাজ ফেলে নামা যায় না', 'সবাই তো এভাবেই কাজ শেষ করে', 'ঠিক আছে, শুধু শেষ বল্টুটা লাগাই'],
    asks: ['ও বলছে শেষ করে নামতে। আপনি কী করবেন?', 'আকাশের কথা শুনবেন, না ওর?', 'থামবেন, না আর একটু চালাবেন?'],
  );

  static const callHeld = 'ঠিক! কোনো কাজ জীবনের চেয়ে বড় নয়।';
  static const allSet = 'আকাশ পড়তে শিখে গেছেন — বৃষ্টি, বাতাস, বজ্র দেখে ঠিক সময়ে না বলা।';
  static const quick = 'নিখুঁত আর ঝটপট!';
  static const fail = 'আরেকবার — আকাশ, বাতাস, ডকেট দেখে সিদ্ধান্ত।';
  static const deadlyWord = 'থামুন!';
  static const nearMissWord = 'অল্পের জন্য!';

  // "আজ যা ধরলেন".
  static const caughtBolt = 'বজ্র দেখেই নেমে এসেছেন';
  static const caughtFar = 'দূরের বজ্রও রেড লাইন';
  static const caughtWind = 'জোর বাতাসে উঁচুতে কাজ বন্ধ';
  static const caughtRain = 'বৃষ্টিতে সাধারণ কাজ বন্ধ';
  static const caughtGloves = 'বৃষ্টিতে জরুরি কাজ, গ্লাভস পরে';
  static const caughtGo = 'আবহাওয়া দেখে তবে কাজ';
  static const caughtCall = 'চাপে “না” বলেছেন';

  /// The sign's name (shown once the reason is paid).
  static String signBn(SkySign s, SkyCase c) => switch (s) {
        SkySign.wet => 'ভেজা পোল',
        SkySign.wind => 'তার দুলছে · ${kmh(c.windKmh)}',
        SkySign.bolt => c.bolt == SkyBolt.near ? 'কাছে বজ্র' : 'দূরে বজ্র',
      };
}

abstract final class SkyMistakes {
  static const _bolt = 'assets/game/art/storm_board/sky_bolt.svg';
  static const _wind = 'assets/game/art/storm_board/sky_wind.svg';
  static const _rain = 'assets/game/art/storm_board/sky_rain.svg';
  static const _gloves = 'assets/game/art/storm_board/sky_gloves.svg';
  static const _check = 'assets/game/art/storm_board/sky_check.svg';

  static const stayBolt = DoMistake(
    key: '1.9/sky/stay-in-lightning',
    textBn: 'বজ্র দেখলে বা শুনলে — উঁচুতে কাজ বন্ধ, নেমে নিরাপদ আশ্রয়ে যান। বজ্রে কোনো পিপিই কাজ করে না, এটাই রেড লাইন।',
    art: _bolt,
    deadly: true,
    lessonPoint: 1,
  );
  static const stayWind = DoMistake(
    key: '1.9/sky/stay-in-wind',
    textBn: 'বাতাস 40–50 km/h ছাড়ালে উঁচুতে কাজ বন্ধ — তার দুলে ফেজে ফেজে শর্ট হতে পারে, পোলে ভারসাম্যও হারাবেন। সন্দেহ হলে কাজ স্থগিত।',
    art: _wind,
    lessonPoint: 2,
  );
  static const stayRain = DoMistake(
    key: '1.9/sky/maintenance-in-rain',
    textBn: 'সাধারণ রক্ষণাবেক্ষণ বৃষ্টিতে বন্ধ — ভেজা পোল, ক্রস-আর্ম, মই পিছল; ভেজা আবহাওয়ায় আর্ক ফ্ল্যাশের ঝুঁকিও বাড়ে।',
    art: _rain,
    lessonPoint: 0,
  );
  static const noGloves = DoMistake(
    key: '1.9/sky/no-waterproof-gloves',
    textBn: 'বৃষ্টিতে শুধু জরুরি ফল্ট মেরামত চলে — সর্বোচ্চ সতর্কতা আর ওয়াটারপ্রুফ গ্লাভস নিয়ে। গ্লাভস ছাড়া নয়।',
    art: _gloves,
    lessonPoint: 0,
  );
  /// Pro tip 1 (check the weather at the start and during the work). The
  /// pro tips are not a lesson point, so no point: "পাঠে দেখুন" opens the
  /// lesson from its start (the reader cannot open at the pro tips yet).
  static const unchecked = DoMistake(
    key: '1.9/sky/unchecked-weather',
    textBn: 'আবহাওয়া না দেখেই কাজ চালালেন। কাজ শুরুর আগে আর চলাকালেও আবহাওয়া দেখুন — বাতাস কত, বৃষ্টি আছে কি না।',
    art: _check,
  );

  static const all = [stayBolt, stayWind, stayRain, noGloves, unchecked];
}

@immutable
class SkyDeal {
  const SkyDeal({required this.cases, required this.callAt});
  final List<SkyCase> cases;

  /// The moment the careless coworker comes: one where the work must stop.
  final int callAt;
}

/// Four moments (four jobs): one where the work goes on (a calm sky, or an
/// emergency repair in a drizzle), one strong wind, one lightning (far, or
/// near in a drizzle) at the 3rd or 4th moment, and one more (drizzle at
/// general maintenance most often). Wind readings: work-on moments 10–25 km/h,
/// strong wind 45–65 km/h (never the 26–44 grey zone, where the lesson's "in
/// doubt, stop" would make either call fair).
SkyDeal dealSky(math.Random rng) {
  int pick(List<int> l) => l[rng.nextInt(l.length)];
  SkyJob anyJob() => rng.nextBool() ? SkyJob.maintenance : SkyJob.emergency;
  final go = rng.nextInt(3) == 0 ? SkyKind.rainUrgent : SkyKind.calm;
  final roll = rng.nextInt(20);
  final extra = roll < 8
      ? SkyKind.rainJob
      : roll < 12
          ? SkyKind.calm
          : roll < 17
              ? SkyKind.rainUrgent
              : SkyKind.wind;
  final bolt = rng.nextInt(10) < 6 ? SkyKind.boltFar : SkyKind.boltNear;
  final kinds = [go, SkyKind.wind, extra]..shuffle(rng);
  kinds.insert(2 + rng.nextInt(2), bolt);
  final cases = <SkyCase>[
    for (final (i, k) in kinds.indexed)
      SkyCase(
        id: 's$i',
        kind: k,
        job: switch (k) {
          SkyKind.rainJob => SkyJob.maintenance,
          SkyKind.rainUrgent || SkyKind.boltNear => SkyJob.emergency,
          _ => anyJob(),
        },
        windKmh: switch (k) {
          SkyKind.wind => pick(const [45, 50, 55, 60, 65]),
          _ => pick(const [10, 15, 20, 25]),
        },
      ),
  ];
  final stops = [
    for (final (i, c) in cases.indexed)
      if (c.mustStop) i,
  ];
  return SkyDeal(cases: cases, callAt: stops[rng.nextInt(stops.length)]);
}

/// The play state (pure logic).
class SkyRun {
  SkyRun(this.deal);
  final SkyDeal deal;
  int index = 0;
  final Set<SkyCheck> checks = {};
  final Set<SkySign> spotted = {};

  /// Taps on this moment's scene that found no sign really there.
  int misses = 0;
  bool shown = false;
  int slips = 0;

  /// Stops where the lesson lets the work go on (not scored).
  int needless = 0;
  DoMistake? deadly;
  final List<String> caught = [];

  bool get done => index >= deal.cases.length;
  bool get ended => done || deadly != null;
  SkyCase get current => deal.cases[index.clamp(0, deal.cases.length - 1)];
  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  /// Read the sky fully (+5): every sign spotted, the weather checked, and no
  /// more than one tap on a sign that is not there — tapping all over the
  /// scene is not reading it (every tap looks the same before the decision).
  bool get thorough => checks.contains(SkyCheck.phone) && spotted.containsAll(current.signs) && misses <= 1;

  void check(SkyCheck c) {
    if (!ended && !shown) checks.add(c);
  }

  /// Taps the scene where [hit] signs are; returns the ones really there
  /// (kept for the +5 and the named rings; the page shows no difference).
  Set<SkySign> spot(Iterable<SkySign> hit) {
    if (ended || shown) return const {};
    final real = hit.where(current.signs.contains).toSet();
    spotted.addAll(real);
    if (real.isEmpty) misses++;
    return real;
  }

  void _tag(String t) {
    if (!caught.contains(t)) caught.add(t);
  }

  /// Stop and come down ([stop]) or work on. Returns the mistake, if any.
  /// Stopping where the lesson lets the work go on is not scored: no
  /// mistake, nothing shown — [shown] stays false and the moment stays (see
  /// [needless]). [pushed]: worked on because the coworker said so.
  DoMistake? decide({required bool stop, bool pushed = false}) {
    if (ended || shown) return null;
    final c = current;
    if (stop && !c.mustStop) {
      needless++;
      return null;
    }
    shown = true;
    if (!stop) {
      switch (c.hazard) {
        case SkyHazard.bolt:
          return deadly = SkyMistakes.stayBolt;
        case SkyHazard.wind:
          slips++;
          return SkyMistakes.stayWind;
        case SkyHazard.rainJob:
          slips++;
          return SkyMistakes.stayRain;
        case null:
          break;
      }
      if (pushed || !checks.contains(SkyCheck.phone)) {
        slips++;
        return SkyMistakes.unchecked;
      }
      if (c.needsGloves && !checks.contains(SkyCheck.gloves)) {
        slips++;
        return SkyMistakes.noGloves;
      }
      _tag(c.needsGloves ? SkyLines.caughtGloves : SkyLines.caughtGo);
      return null;
    }
    switch (c.hazard!) {
      case SkyHazard.bolt:
        _tag(SkyLines.caughtBolt);
        if (c.bolt == SkyBolt.far) _tag(SkyLines.caughtFar);
      case SkyHazard.wind:
        _tag(SkyLines.caughtWind);
      case SkyHazard.rainJob:
        _tag(SkyLines.caughtRain);
    }
    return null;
  }

  void next() {
    index++;
    checks.clear();
    spotted.clear();
    misses = 0;
    shown = false;
  }
}

/// The quick bonus: a little under a thorough play (~85 %, rounded to 10 s,
/// as pole_read). The clock runs from the end of the guide's intro to the last
/// paid reason. A thorough moment (ms; ~1500 human reaction per action):
///   the weather turns                                      2200
///   tap the sign 1500 + ring 1000                          2500
///   the phone: open 1500, read 1500, close 1000            4000
///   gloves (an emergency drizzle ~1 in 2 plays)             750
///   decide                                                 1500
///   reason: praise ~1500 + 650 gap + deck 910 + read 2000
///     + pick 1500 + "এই তো আসল কথা" ~1200 + 450           8210
///   the signs named                                        1400
///   = 20560 × 4                                           82240
/// + the coworker once: his line ~3000 + deck 910 + read and pick 3500 + 420
///   + his wait when the stop was pressed first ~1800       9630
/// ≈ 91870 ms; 85 % ≈ 78100 → 80 s.
const kSkyQuickMs = 80000;

@immutable
class SkyReadPack {
  const SkyReadPack({required this.id, required this.titleBn, this.quickMs = kSkyQuickMs});
  final String id;
  final String titleBn;
  final int quickMs;
}

const skyReadPacks = {
  'do_1_9_a': SkyReadPack(id: 'do_1_9_a', titleBn: SkyLines.title),
};

/// Where each sign is in the scene (design px).
Rect skySignRect(SkySign s, SkyGeo geo, SkyBolt bolt) => switch (s) {
      SkySign.wet => Rect.fromLTRB(SkyGeo.cx - 30, geo.topY - 6, SkyGeo.cx + 30, geo.groundY + 40),
      SkySign.wind => Rect.fromLTRB(0, geo.pins[1].dy - 26, 360, geo.armY + 80 * geo.s),
      SkySign.bolt => bolt == SkyBolt.near ? Rect.fromLTRB(236, 0, 360, geo.horizonY + 30) : Rect.fromLTRB(196, geo.horizonY - 224, 360, geo.horizonY + 6),
    };

/// The trees count as the wind's sign too.
Rect skyTreesRect(SkyGeo geo) => Rect.fromLTRB(150, geo.horizonY - 110, 360, geo.horizonY + 40);

// ============================================================================
// Page
// ============================================================================

class SkyReadPage extends StatefulWidget {
  const SkyReadPage({super.key, required this.ctx, required this.pack, this.muted = false, this.seed});

  final LevelContext ctx;
  final SkyReadPack pack;
  final bool muted;
  final int? seed;

  @override
  State<SkyReadPage> createState() => _SkyReadPageState();
}

class _SkyReadPageState extends State<SkyReadPage> {
  int _round = 0;
  late bool _muted = widget.muted;

  @override
  Widget build(BuildContext context) => _SkyRunPage(
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

class _SkyRunPage extends ConsumerStatefulWidget {
  const _SkyRunPage({super.key, required this.ctx, required this.pack, required this.muted, required this.rng, required this.onRetry});

  final LevelContext ctx;
  final SkyReadPack pack;
  final bool muted;
  final math.Random rng;
  final ValueChanged<bool> onRetry;

  @override
  ConsumerState<_SkyRunPage> createState() => _SkyRunPageState();
}

enum _Verdict { stopped, working }

class _SkyRunPageState extends ConsumerState<_SkyRunPage>
    with DoDeathGuard, DoStrikeOut, TickerProviderStateMixin, ReasonTable, CoworkerMoment {
  final _scoreKey = GlobalKey();
  late final SkyRun _run = SkyRun(dealSky(widget.rng));
  final _clock = Stopwatch();
  late bool _muted = widget.muted;
  final _wrongBag = LineBag(LearnFeedbackLines.wrong);

  /// The weather turning at the start of a moment (0 → 1).
  late final AnimationController _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _turned();
    });

  /// Coming down the pole (0 → 0.75), then stepping away from it (→ 1).
  late final AnimationController _down = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  /// A lightning flash (one-shot; the painter repaints itself).
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final Listenable _sceneMotion = Listenable.merge([_turn, _down]);

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
  _Verdict? _verdict;
  var _revealed = false;
  var _coworkerArmed = false;

  /// The phone's weather is open.
  var _phone = false;

  /// Where he tapped the scene this moment (design px), each with an id for
  /// its key: the same plain mark for every tap, real sign or not.
  final List<(int, Offset)> _taps = [];
  int _tapN = 0;

  /// The moment whose weather has turned (its cues run once).
  int _turnedFor = -1;

  /// The thunder's sound word, while it rolls.
  String? _word;
  int _words = 0;
  Timer? _wordTimer;
  Timer? _flashTimer;
  Timer? _againTimer;
  /// A flash a moment ago: a tap does not bring another yet.
  Timer? _coolTimer;
  var _cool = false;

  /// Stop was pressed on his moment before he came: he comes now.
  Offset? _heldStop;

  var _freeze = false;
  Completer<void>? _frozen;
  final _nudge = TaskNudge();
  int _nudgeN = 0;

  @override
  LevelContext get deathCtx => widget.ctx;
  String get _rungId => widget.ctx.rungId;
  bool get _quiet => MediaQuery.disableAnimationsOf(context) || slmReduceMotion(context);
  bool get _turning => _turn.isAnimating;
  bool get _downing => _down.isAnimating;

  @override
  void dispose() {
    disposeCoworker();
    _wordTimer?.cancel();
    _flashTimer?.cancel();
    _againTimer?.cancel();
    _coolTimer?.cancel();
    _turn.dispose();
    _down.dispose();
    _flash.dispose();
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
    _startMoment();
  }

  bool get _canPlay =>
      !_intro && !_busy && !_ended && _card == null && !reasonOpen && !coworkerOpen && !_run.shown && !_phone && !_turning && !_downing;

  // --- a moment: the weather turns ----------------------------------------------
  void _startMoment() {
    _flashTimer?.cancel();
    _againTimer?.cancel();
    _wordTimer?.cancel();
    setState(() {
      _verdict = null;
      _revealed = false;
      _phone = false;
      _word = null;
      _taps.clear();
      _wake++;
    });
    _down.value = 0;
    _flash.value = 0;
    if (!_coworkerArmed && _run.index == _run.deal.callAt) {
      _coworkerArmed = true;
      scheduleCoworker();
    }
    if (_quiet) {
      // Setting 1 may fire the status listener (from dismissed); _turned runs
      // once a moment either way.
      _turn.value = 1;
      _turned();
    } else {
      unawaited(_turn.forward(from: 0));
    }
  }

  void _turned() {
    if (!mounted || _ended || _turnedFor == _run.index) return;
    _turnedFor = _run.index;
    final c = _run.current;
    setState(() => _wake++);
    if (c.windy) _cue('sounds/learn/wind_gust.wav', volume: 0.6);
    if (c.bolt != SkyBolt.none) {
      _strike();
      // The storm goes on: one more flash a little later.
      _againTimer = Timer(const Duration(milliseconds: 4200), () {
        if (mounted && !_run.shown && !_ended) _strike();
      });
    }
    unawaited(_sayChain([SkyLines.ask]));
  }

  /// A flash, then its thunder (far: the roll comes a moment later).
  void _strike() {
    final c = _run.current;
    if (c.bolt == SkyBolt.none || _ended) return;
    _cool = true;
    _coolTimer?.cancel();
    _coolTimer = Timer(const Duration(milliseconds: 3000), () => _cool = false);
    final near = c.bolt == SkyBolt.near;
    if (_quiet) {
      // Reduce motion: one still bright frame instead of the strobe.
      _flash.value = 0.08;
      _flashTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) _flash.value = 0;
      });
    } else {
      unawaited(_flash.forward(from: 0));
    }
    HapticFeedback.mediumImpact();
    void roll() {
      if (!mounted || _ended) return;
      _cue(near ? 'sounds/learn/thunder_near.wav' : 'sounds/learn/thunder_far.wav', volume: near ? 0.9 : 0.7);
      _wordTimer?.cancel();
      setState(() {
        _word = near ? SkyLines.crack : SkyLines.rumble;
        _words++;
      });
      _wordTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _word = null);
      });
    }

    if (near) {
      roll();
    } else {
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 900), roll);
    }
  }

  // --- hands on -----------------------------------------------------------------------
  void _tapScene(Offset p, SkyGeo geo) {
    if (!_canPlay) return;
    final c = _run.current;
    final hit = <SkySign>{
      for (final s in SkySign.values)
        if (skySignRect(s, geo, c.bolt).contains(p)) s,
      if (skyTreesRect(geo).contains(p)) SkySign.wind,
    };
    // Recorded for the +5 and the named rings after the reason; on screen
    // every tap is the same plain mark, sound and haptic (no tell).
    _run.spot(hit);
    HapticFeedback.selectionClick();
    _cue('sounds/intro/tick.ogg', volume: 0.45);
    setState(() {
      _taps.add((_tapN++, p));
      if (_taps.length > 5) _taps.removeAt(0);
      _wake++;
    });
    // The storm goes on: another flash (whatever was tapped).
    if (c.bolt != SkyBolt.none && !_cool) _strike();
  }

  void _openPhone() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/quiz_select.wav', volume: 0.45);
    _run.check(SkyCheck.phone);
    setState(() => _phone = true);
  }

  void _closePhone() {
    if (!_phone) return;
    _cue('sounds/intro/click.ogg', volume: 0.4);
    setState(() {
      _phone = false;
      _wake++;
    });
  }

  void _putGloves() {
    if (!_canPlay) return;
    HapticFeedback.selectionClick();
    _cue('sounds/learn/tag_slap.wav', volume: 0.35);
    _run.check(SkyCheck.gloves);
    setState(() => _wake++);
  }

  bool get _gloved => _run.checks.contains(SkyCheck.gloves);

  // --- the decision ----------------------------------------------------------------
  Future<void> _decide(bool stop, Offset origin) async {
    if (!_canPlay) return;
    // On his moment he cuts in the moment the trainee goes to come down.
    if (stop && _run.index == _run.deal.callAt && !coworkerDone) {
      _hush();
      HapticFeedback.selectionClick();
      setState(() {
        _heldStop = origin;
        _busy = true;
      });
      return;
    }
    await _commit(stop, origin);
  }

  Future<void> _commit(bool stop, Offset origin, {bool pushed = false}) async {
    _hush();
    _busy = false;
    _heldStop = null;
    final m = _run.decide(stop: stop, pushed: pushed);
    if (m == null && !_run.shown) {
      // A stop where the lesson lets the work go on: not scored, he stays up;
      // the guide says the lesson's rule and the moment is still to read.
      HapticFeedback.selectionClick();
      _cue('sounds/intro/click.ogg', volume: 0.5);
      setState(() => _wake++);
      unawaited(_sayChain([SkyLines.needless(_run.current)]));
      return;
    }
    _againTimer?.cancel();
    HapticFeedback.mediumImpact();
    if (m == null) {
      _cue('sounds/learn/tag_slap.wav', volume: 0.7);
      _cue('sounds/quiz_right.wav', volume: 0.6);
      setState(() {
        _verdict = stop ? _Verdict.stopped : _Verdict.working;
        _wake++;
      });
      if (stop) {
        if (_quiet) {
          _down.value = 1;
        } else {
          unawaited(_down.forward(from: 0));
        }
      }
      putOnTable(15 + (_run.thorough ? 5 : 0));
      final c = _run.current;
      final idx = _run.index;
      unawaited(askReason(
        deal: () => dealChoices(SkyLines.whyRight(c), SkyLines.whyWrong(c), widget.rng),
        question: stop ? SkyLines.whyStop : SkyLines.whyGo,
        stillValid: () => _run.index == idx && !_ended,
      ));
      return;
    }
    if (m.deadly) {
      await _deadly(m);
      return;
    }
    setState(() {});
    unawaited(_levelDelta(-10, origin, mood: GuideMood.warn));
    await _slip(m);
  }

  void _next() {
    _run.next();
    if (_run.done) {
      unawaited(_finish());
      return;
    }
    _startMoment();
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
    final signs = _run.current.signs.isNotEmpty;
    if (signs) setState(() => _revealed = true);
    unawaited(Future<void>.delayed(Duration(milliseconds: !signs ? 300 : (_quiet ? 700 : 1500)), () {
      if (mounted && !_ended && _run.index == idx) _next();
    }));
  }

  // --- the shared pressure moment (CoworkerMoment) ----------------------------
  @override
  CoworkerScript get coworkerScript => SkyLines.coworker;
  @override
  math.Random get coworkerRng => widget.rng;
  @override
  bool get coworkerMuted => _muted;
  @override
  bool? coworkerCanCome() {
    if (_ended || _run.index != _run.deal.callAt || _run.shown) return null;
    if (_heldStop != null) return true;
    if (_intro || _busy || _turning || _card != null || reasonOpen || _phone) return false;
    return true;
  }

  @override
  Future<void> coworkerGuideSay(List<String> lines, {GuideMood mood = GuideMood.talk}) => _sayChain(lines, mood: mood);
  @override
  void coworkerHush() => _hush();

  @override
  Future<void> onCoworkerAnswer(bool held, Offset origin, {required bool direct}) async {
    if (!held) {
      // Listened to him: works on (deadly in lightning; a slip otherwise).
      await _commit(false, origin, pushed: true);
      return;
    }
    _run.caught.add(SkyLines.caughtCall);
    unawaited(_levelDelta(10, origin, mood: GuideMood.glad));
    unawaited(coworkerSnarl());
    // Refused: down the pole now.
    await _commit(true, origin);
  }

  /// Tap the guide: the task again, a different way each time.
  void _tapGuide() {
    if (_intro || _ended) return;
    final String line = coworkerOpen
        ? nextCoworkerAsk()
        : reasonOpen
            ? SkyLines.tapWhy[_nudgeN++ % SkyLines.tapWhy.length]
            : _nudge.next(SkyLines.ask);
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
    final speak = await SpokenOnce.first('sky/${m.key}');
    if (!mounted || _card != m) return;
    await _sayChain([speak ? m.textBn : _wrongBag.next().shownBn], mood: GuideMood.warn);
  }

  /// On the pole in lightning: the roadside freezes grey and the strike comes
  /// down on the pole in colour; then near-miss or death.
  Future<void> _deadly(DoMistake m) async {
    if (_ended) return;
    _ended = true;
    _busy = true;
    _clock.stop();
    _hush();
    _flashTimer?.cancel();
    _againTimer?.cancel();
    HapticFeedback.heavyImpact();
    _cue('sounds/learn/thunder_near.wav', volume: 1);
    final frozen = _frozen = Completer<void>();
    setState(() {
      _freeze = true;
      _phone = false;
      _word = null;
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
    final speak = await SpokenOnce.first('sky/${m.key}');
    if (!mounted) return;
    await _sayChain([death ? SkyLines.deadlyWord : SkyLines.nearMissWord, if (speak) m.textBn], mood: GuideMood.warn);
  }

  void _cardGo() {
    switch (_cardTone) {
      case MistakeTone.slip:
        _hush();
        setState(() => _card = null);
        _next();
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
    await _say(!_run.passed ? SkyLines.fail : (_quickBonus ? SkyLines.quick : SkyLines.allSet), mood: _run.passed ? GuideMood.celebrate : GuideMood.warn);
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
    if (_downing) return LinemanMode.walk;
    if (_card != null && _cardTone == MistakeTone.slip) return LinemanMode.worried;
    if (_heldStop != null || coworkerOpen) return LinemanMode.worried;
    if (_verdict == _Verdict.working) return LinemanMode.cheer;
    return LinemanMode.hold;
  }

  /// The trainee's box: up at the cross-arm, facing the pole (left of it);
  /// [down] 0 → 0.75 climbs down, then he steps away from the pole.
  static Rect traineeBox(SkyGeo geo, double down) {
    final h = 1.95 * geo.ppm;
    final w = h / 2;
    final upTop = geo.armY + 10 * geo.s;
    final groundTop = geo.groundY - h + 2;
    final k = Curves.easeInOut.transform((down / 0.75).clamp(0.0, 1.0));
    final away = Curves.easeOut.transform(((down - 0.75) / 0.25).clamp(0.0, 1.0)) * 70;
    final left = SkyGeo.cx - w * 0.86 - away;
    return Rect.fromLTWH(left, upTop + (groundTop - upTop) * k, w, h);
  }

  List<Widget> _scene(SceneMetrics m) {
    final geo = SkyGeo.forScene(m.height, m.inset);
    final c = _run.current;
    final quiet = _quiet;
    final turn = Curves.easeInOut.transform(_turn.value);
    final weather = SkyWeather.lerp(SkyWeather.fair, c.weather, turn);
    final down = _down.value;
    final tb = traineeBox(geo, down);
    final hand = tb.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, tb.size);
    final grey = _freeze ? freezeFilter : const ColorFilter.mode(Color(0x00000000), BlendMode.dst);
    final up = down < 0.05;
    // The real signs are named only once the reason is paid (as pole_read);
    // before the decision every tap shows the same plain mark.
    final named = _revealed && _run.shown && !_freeze;
    final rings = named ? c.signs : const <SkySign>{};
    final marks = !_run.shown && !_freeze;
    // The stamp sits right of the pole top; where a named ring (the near
    // strike, the galloping wires) would meet it, it drops below the ring and
    // its label so they never overlap (any width, any height).
    const stampW = 170.0;
    final stampLeft = SkyGeo.cx + 40 * geo.s;
    var stampTop = math.max(geo.topY + 30, 150.0);
    for (final s in const [SkySign.wind, SkySign.bolt]) {
      if (!c.signs.contains(s)) continue;
      final r = _ringRect(s, geo, c.bolt);
      final meetsX = r.left < stampLeft + stampW && r.right > stampLeft;
      if (meetsX && stampTop < r.bottom + 30 && stampTop + 56 > r.top) stampTop = r.bottom + 36;
    }
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
                  key: const ValueKey('land'),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: SkyWorldPainter(geo: geo, weather: weather, t: t, flash: _flash, seed: _run.index * 7 + 1)),
                  ),
                ),
                Positioned.fromRect(
                  key: const ValueKey('trainee'),
                  rect: tb,
                  child: LinemanFigure(look: LinemanLook.trainee, mode: _mode, wake: _wake, quiet: quiet),
                ),
                // The step he stands on and his pole strap round the pole.
                if (up)
                  Positioned.fill(
                    key: const ValueKey('strap'),
                    child: CustomPaint(painter: _StrapPainter(box: tb, geo: geo)),
                  ),
                // The waterproof gloves on his hands.
                if (_gloved && up && _mode == LinemanMode.hold)
                  Positioned(
                    key: const ValueKey('gloves'),
                    left: hand.dx - 9,
                    top: hand.dy - 9,
                    width: 18,
                    height: 18,
                    child: const IgnorePointer(child: CustomPaint(painter: _GlovePainter())),
                  ),
                Positioned.fill(
                  key: const ValueKey('rain'),
                  child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: SkyRainPainter(weather: weather, t: t)))),
                ),
              ],
            ),
          ),
        ),
      ),
      // Where he tapped: one plain mark per tap, the same for every tap.
      if (marks)
        for (final (id, p) in _taps)
          Positioned(
            key: ValueKey('tap-$id'),
            left: p.dx - 15,
            top: p.dy - 15,
            width: 30,
            height: 30,
            child: IgnorePointer(child: _TapMark(quiet: quiet)),
          ),
      // The real signs, named, once the reason is paid.
      for (final s in rings)
        Positioned.fromRect(
          key: ValueKey('ring-${s.name}'),
          rect: _ringRect(s, geo, c.bolt),
          child: IgnorePointer(child: _SignRing(text: SkyLines.signBn(s, c), quiet: quiet)),
        ),
      // The thunder's word (the sound, never its meaning).
      if (_word != null && !_freeze)
        Positioned(
          key: const ValueKey('thunder-word'),
          left: c.bolt == SkyBolt.near ? 210 : 196,
          top: c.bolt == SkyBolt.near ? geo.horizonY * 0.42 : geo.horizonY - 250,
          child: IgnorePointer(child: _SoundWord(key: ValueKey('word-$_words'), text: _word!, quiet: quiet)),
        ),
      if (_verdict != null && !_freeze)
        Positioned(
          key: ValueKey('stamp-${_run.index}'),
          left: stampLeft,
          width: stampW,
          top: stampTop,
          child: IgnorePointer(child: _StampPop(text: _verdict == _Verdict.stopped ? SkyLines.stampStop : SkyLines.stampGo, quiet: quiet)),
        ),
      // Tap the sky, the wires, the pole: read the signs.
      Positioned.fill(
        key: const ValueKey('touch'),
        child: Semantics(
          label: SkyLines.sceneLabel,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: (d) => _tapScene(d.localPosition, geo)),
        ),
      ),
      // The strike on the pole, in colour over the grey roadside.
      if (_freeze)
        Positioned.fill(
          key: const ValueKey('strike'),
          child: IgnorePointer(child: _StrikeView(geo: geo, quiet: quiet)),
        ),
      // The next job: a short fade from the last one.
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

  static Rect _ringRect(SkySign s, SkyGeo geo, SkyBolt bolt) {
    final centre = switch (s) {
      SkySign.wet => Offset(SkyGeo.cx + 2, geo.topY + geo.length * 0.55),
      SkySign.wind => Offset((geo.pins[2].dx + geo.farPins[2].dx) / 2, (geo.pins[2].dy + geo.farPins[2].dy) / 2 + 26 * geo.s),
      SkySign.bolt => bolt == SkyBolt.near ? Offset(300, geo.horizonY * 0.55) : Offset(290, geo.horizonY - 110),
    };
    return Rect.fromCenter(center: centre, width: 76, height: 76);
  }

  @override
  Widget build(BuildContext context) {
    final quiet = _quiet;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final playing = !_intro && _mark == null && !struckOut && !_freeze;
    final deckUp = reasonOpen || coworkerChoiceUp;
    final handsOn = playing && !_run.shown && !deckUp && !coworkerOpen && _card == null && !_phone && _heldStop == null;
    final c = _run.current;
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
              labels: SkyLines.rounds,
              done: {for (var i = 0; i < math.min(_run.index, 4); i++) i},
              current: _run.done ? null : _run.index,
              quiet: quiet,
            ),
            animation: _sceneMotion,
            layers: (context, m) => _scene(m),
            overlays: [
              // The docket (hidden while his speech bubble is up, which covers it).
              if (playing && !_run.done && !coworkerOpen)
                Positioned(
                  key: ValueKey('docket-${_run.index}'),
                  left: 12,
                  top: pad.top + 96,
                  child: IgnorePointer(child: _DocketChip(job: c.job)),
                ),
              ...tableLayers(at: Offset(size.width / 2, pad.top + 150), quiet: quiet),
              if (handsOn) ...[
                Positioned(
                  key: const ValueKey('hud-tools'),
                  left: 10,
                  bottom: pad.bottom + 72,
                  child: Row(
                    children: [
                      _ToolButton(icon: Icons.phone_android_rounded, label: SkyLines.phone, on: _run.checks.contains(SkyCheck.phone), enabled: _canPlay, onTap: _openPhone),
                      const SizedBox(width: 6),
                      _ToolButton(icon: Icons.back_hand_rounded, label: SkyLines.gloves, on: _gloved, enabled: _canPlay, onTap: _putGloves),
                    ],
                  ),
                ),
                Positioned(
                  key: const ValueKey('hud-decide'),
                  left: 12,
                  right: 12,
                  bottom: pad.bottom + 12,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _StopButton(onTapUp: (d) => unawaited(_decide(true, d.globalPosition)))),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: DoBigButton(label: SkyLines.go, filled: true, onTapUp: (d) => unawaited(_decide(false, d.globalPosition)))),
                    ],
                  ),
                ),
              ],
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
              if (_phone && playing) _PhoneCard(key: const ValueKey('phone'), sky: c, quiet: quiet, onClose: _closePhone),
              if (playing && _card == null && !_phone) cornerGuide(onTap: _tapGuide, bottom: pad.bottom + (deckUp ? 236 : 72), onLeft: coworkerFromRight),
              ?coworkerPeek(quiet: quiet, key: const ValueKey('coworker')),
              if (_card != null)
                MistakeCard(
                  key: ValueKey('card-${_card!.key}-${_run.index}'),
                  mistake: _card!,
                  tone: _cardTone,
                  quiet: quiet,
                  // No lesson point (the pro-tip card): the lesson from its start.
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
                  line: SkyLines.intro,
                  alarm: 'sounds/learn/thunder_far.wav',
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

/// His pole strap: from his hips round the pole.
class _StrapPainter extends CustomPainter {
  const _StrapPainter({required this.box, required this.geo});
  final Rect box;
  final SkyGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final half = 6 * geo.s + 2;
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    // The step bolt under his boots.
    final feet = box.bottom - 3;
    c.drawRect(Rect.fromLTRB(box.left + box.width * 0.3, feet, SkyGeo.cx, feet + 3.2), Paint()..color = const Color(0xFF5A6066));
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(SkyGeo.cx - half, hip.dy - 10, SkyGeo.cx + half + 3, hip.dy - 6)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(SkyGeo.cx - half, hip.dy + 4, SkyGeo.cx + half + 3, hip.dy - 6),
        strap);
  }

  @override
  bool shouldRepaint(_StrapPainter old) => old.box != box || old.geo != geo;
}

/// A blue waterproof rubber glove on his hand: the mitt, the thumb and the
/// long cuff (drawn bigger than the hand so it reads at the figure's size).
class _GlovePainter extends CustomPainter {
  const _GlovePainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF3F86D8), Color(0xFF1B4F94)]).createShader(Offset.zero & size);
    final edge = Paint()
      ..color = const Color(0xFF0B2A55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    // The cuff, up the wrist.
    final cuff = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, 0, w * 0.44, h * 0.42), Radius.circular(w * 0.08));
    // The mitt (fingers together) and the thumb.
    final mitt = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.34, w * 0.6, h * 0.62), Radius.circular(w * 0.28));
    final thumb = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.04, h * 0.42, w * 0.3, h * 0.2), Radius.circular(w * 0.1));
    for (final r in [cuff, thumb, mitt]) {
      c.drawRRect(r, fill);
      c.drawRRect(r, edge);
    }
    // The cuff's rim.
    c.drawLine(Offset(w * 0.28, h * 0.34), Offset(w * 0.72, h * 0.34), edge);
  }

  @override
  bool shouldRepaint(_GlovePainter old) => false;
}

class _DocketChip extends StatelessWidget {
  const _DocketChip({required this.job});
  final SkyJob job;

  @override
  Widget build(BuildContext context) {
    // One plain style for both jobs: the words say which, no colour cue.
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
          Text(SkyLines.docket, style: bangla(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF6B5B3A))),
          Text(SkyLines.jobBn(job), style: bangla(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF2B2416))),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTapUp});
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60B1324),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SlmColors.warning.withValues(alpha: 0.9), width: 1.8),
          ),
          child: Text(SkyLines.stop, textAlign: TextAlign.center, style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.ivory)),
        ),
      ),
    );
  }
}

/// A hands-on tool: a round icon with its name under it; lit once used.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.on, required this.enabled, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final bool enabled;
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
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: on ? const [Color(0xFF1F4A33), Color(0xFF0B2418)] : const [Color(0xFF1C2E4A), Color(0xFF0B1324)],
                  ),
                  border: Border.all(color: ring.withValues(alpha: 0.9), width: 1.7),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Icon(icon, size: 24, color: ring),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xCC0B1324), borderRadius: BorderRadius.circular(8)),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: bangla(fontSize: 11, fontWeight: FontWeight.w800, height: 1.15, color: SlmColors.ivory)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone's weather: the wind and the rain now (lesson pro tip 1). Tap
/// anywhere to put it away.
class _PhoneCard extends StatelessWidget {
  const _PhoneCard({super.key, required this.sky, required this.quiet, required this.onClose});
  final SkyCase sky;
  final bool quiet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF8FC3F2)),
              const SizedBox(width: 10),
              Expanded(child: Text(k, style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFC9D6E4)))),
              Text(v, style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        );
    return Positioned.fill(
      child: Semantics(
        label: SkyLines.phoneClose,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: ColoredBox(
            color: const Color(0x66050A16),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.translate(offset: Offset(0, 60 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A2B),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFF2D3B52), width: 6),
                    boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFF2D3B52), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.cloud_rounded, color: Color(0xFFFFD34E), size: 20),
                          const SizedBox(width: 6),
                          Text(SkyLines.phone, style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                      const Divider(color: Color(0xFF2D3B52), height: 18),
                      row(Icons.air_rounded, SkyLines.phoneWind, SkyLines.kmh(sky.windKmh)),
                      row(Icons.water_drop_rounded, SkyLines.phoneRain, sky.drizzle ? SkyLines.rainLight : SkyLines.rainNone),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where he tapped the scene: a plain white ring, the same for every tap (it
/// never tells whether a sign is there).
class _TapMark extends StatelessWidget {
  const _TapMark({required this.quiet});
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.scale(scale: 1.5 - 0.5 * v, child: Opacity(opacity: (0.4 + 0.6 * v).clamp(0.0, 1.0), child: child)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x22FFFFFF),
          border: Border.all(color: const Color(0xDDFFFFFF), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
        ),
      ),
    );
  }
}

/// A ring round a real sign with its name, once the reason is paid.
class _SignRing extends StatelessWidget {
  const _SignRing({required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: SlmColors.danger, width: 3),
              ),
            ),
          ),
          Positioned(
            top: 72,
            left: -60,
            right: -60,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: SlmColors.danger, borderRadius: BorderRadius.circular(8)),
                child: Text(text, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The thunder's word, popping in the sky.
class _SoundWord extends StatelessWidget {
  const _SoundWord({super.key, required this.text, required this.quiet});
  final String text;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.5 + 0.5 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Text(
        text,
        style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFE8EEFF))
            .copyWith(shadows: const [Shadow(color: Color(0xCC0B1324), blurRadius: 6, offset: Offset(0, 2))]),
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

/// The strike (in colour over the frozen grey scene): a bolt comes down on
/// the pole top, a white flash, sparks off the cross-arm. Non-graphic.
class _StrikeView extends StatelessWidget {
  const _StrikeView({required this.geo, required this.quiet});
  final SkyGeo geo;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (_, v, _) => CustomPaint(painter: _StrikePainter(geo: geo, v: v)),
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.geo, required this.v});
  final SkyGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final hitAt = geo.pins[1];
    // The bolt flickers in the first part, then its afterglow stays.
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final rnd = math.Random(5);
    final pts = <Offset>[Offset(hitAt.dx + 60, -10)];
    for (var i = 1; i < 10; i++) {
      final k = i / 10;
      pts.add(Offset(hitAt.dx + 60 * (1 - k) + (rnd.nextDouble() - 0.5) * 34, -10 + (hitAt.dy + 10) * k));
    }
    pts.add(hitAt);
    final path = Path()..addPolygon(pts, false);
    c.drawPath(
        path,
        Paint()
          ..color = Color.fromRGBO(150, 175, 255, 0.7 * flick)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.drawPath(
        path,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeJoin = StrokeJoin.round);
    // The glow and the sparks at the pole top.
    final r = 30 + 50 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        hitAt,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 245, 200, 0.95 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: hitAt, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 12 + 40 * v;
      final d1 = d0 + 14;
      c.drawLine(hitAt + Offset(math.cos(a) * d0, math.sin(a) * d0), hitAt + Offset(math.cos(a) * d1, math.sin(a) * d1), spark);
    }
    // The first instant whites the screen.
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.85 * white));
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.v != v || old.geo != geo;
}
