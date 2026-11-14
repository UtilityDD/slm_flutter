import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/en_digits.dart';
import 'duty_slip_models.dart';

const dsPlayBadgeBand = 80.0;

enum DsAct { briefing, card, call, lethal, done }

enum DsPlanPhase { cover, road, list, play, result }

enum DsGrade { safe, risky, unsafe }

enum DsLevelRank { darun, motamuti, again }

enum DsLevelKind { letters, job, field }

class DsLevelSpec {
  final int number;
  final DsLevelKind kind;
  final int choices;
  final int darunSec;
  final bool living;

  const DsLevelSpec({
    required this.number,
    required this.kind,
    required this.choices,
    required this.darunSec,
    this.living = false,
  });

  bool get isField => kind == DsLevelKind.field;
  bool get isLetters => kind == DsLevelKind.letters;
  bool get isJob => kind == DsLevelKind.job;
}

class DsResult {
  final bool ok;
  final bool lethal;
  final String noteBn;
  final int delta;
  final int streak;
  final bool gift;

  const DsResult({
    required this.ok,
    this.lethal = false,
    this.noteBn = '',
    this.delta = 0,
    this.streak = 0,
    this.gift = false,
  });
}

/// Admin developer switch. Other accounts never set this; normal and guest
/// accounts unlock one level at a time.
bool devLevelsOpen = false;

bool get dsPlayAllLevels => devLevelsOpen;

const dsLevels = <DsLevelSpec>[
  DsLevelSpec(number: 1, kind: DsLevelKind.letters, choices: 2, darunSec: 150),
  DsLevelSpec(number: 2, kind: DsLevelKind.letters, choices: 4, darunSec: 80),
  DsLevelSpec(number: 3, kind: DsLevelKind.letters, choices: 6, darunSec: 100),
  DsLevelSpec(number: 4, kind: DsLevelKind.letters, choices: 8, darunSec: 180),
  DsLevelSpec(number: 5, kind: DsLevelKind.letters, choices: 8, darunSec: 200),
  DsLevelSpec(number: 6, kind: DsLevelKind.letters, choices: 8, darunSec: 160),
  DsLevelSpec(number: 7, kind: DsLevelKind.letters, choices: 8, darunSec: 180),
  DsLevelSpec(number: 8, kind: DsLevelKind.letters, choices: 8, darunSec: 200),
  DsLevelSpec(number: 9, kind: DsLevelKind.letters, choices: 8, darunSec: 180),
  DsLevelSpec(number: 10, kind: DsLevelKind.letters, choices: 8, darunSec: 200),
  DsLevelSpec(number: 11, kind: DsLevelKind.letters, choices: 8, darunSec: 180),
  DsLevelSpec(number: 12, kind: DsLevelKind.letters, choices: 8, darunSec: 180),
  DsLevelSpec(number: 13, kind: DsLevelKind.letters, choices: 8, darunSec: 200),
  DsLevelSpec(number: 14, kind: DsLevelKind.letters, choices: 8, darunSec: 200),
  // Eight-step mantra quizzes, then the 23-step jobs, then the field night.
  DsLevelSpec(number: 15, kind: DsLevelKind.letters, choices: 2, darunSec: 60),
  DsLevelSpec(number: 16, kind: DsLevelKind.letters, choices: 4, darunSec: 80),
  DsLevelSpec(number: 17, kind: DsLevelKind.letters, choices: 6, darunSec: 100),
  DsLevelSpec(number: 18, kind: DsLevelKind.letters, choices: 8, darunSec: 120),
  DsLevelSpec(number: 19, kind: DsLevelKind.letters, choices: 2, darunSec: 50, living: true),
  DsLevelSpec(number: 20, kind: DsLevelKind.letters, choices: 4, darunSec: 70, living: true),
  DsLevelSpec(number: 21, kind: DsLevelKind.letters, choices: 6, darunSec: 85, living: true),
  DsLevelSpec(number: 22, kind: DsLevelKind.letters, choices: 8, darunSec: 100, living: true),
  DsLevelSpec(number: 23, kind: DsLevelKind.job, choices: 2, darunSec: 75),
  DsLevelSpec(number: 24, kind: DsLevelKind.job, choices: 4, darunSec: 105),
  DsLevelSpec(number: 25, kind: DsLevelKind.job, choices: 6, darunSec: 150),
  DsLevelSpec(number: 26, kind: DsLevelKind.job, choices: 10, darunSec: 180),
  DsLevelSpec(number: 27, kind: DsLevelKind.job, choices: 23, darunSec: 240),
  DsLevelSpec(number: 28, kind: DsLevelKind.job, choices: 2, darunSec: 70, living: true),
  DsLevelSpec(number: 29, kind: DsLevelKind.job, choices: 4, darunSec: 95, living: true),
  DsLevelSpec(number: 30, kind: DsLevelKind.job, choices: 6, darunSec: 135, living: true),
  DsLevelSpec(number: 31, kind: DsLevelKind.job, choices: 10, darunSec: 160, living: true),
  DsLevelSpec(number: 32, kind: DsLevelKind.job, choices: 23, darunSec: 210, living: true),
  DsLevelSpec(number: 33, kind: DsLevelKind.field, choices: 0, darunSec: 0),
];

const dsSafeHome = <DsPlanItem>[
  DsPlanItem(id: 'stop', labelBn: 'থামো ও বিপদ খুঁজো', letter: 'S',
    whyBn: 'তাড়াহুড়ো করলে বিপদ দেখা যায় না। দাঁড়িয়ে চারদিক দেখুন।',
    icon: 'assets/safety/library/ppe/High_Visibility_Vest_3.webp'),
  DsPlanItem(id: 'armour', labelBn: 'কবচ পরো', letter: 'A',
    whyBn: 'PPE ছাড়া লাইনে হাত দিলে শক, পোড়া, পড়ে যাওয়া — তিনটাই হয়।',
    icon: 'assets/safety/library/ppe/Safety_Helmet.webp'),
  DsPlanItem(id: 'form', labelBn: 'পারমিট নাও', letter: 'F',
    whyBn: 'পারমিট (PTW) ছাড়া কেউ জানে না আপনি লাইনে — যে কোনো সময় চালু করতে পারে।',
    icon: 'assets/zero_loss/scene/gear_ptw.webp'),
  DsPlanItem(id: 'end', labelBn: 'দুদিক কাটো', letter: 'E',
    whyBn: 'লাইন কাটা না হলে কারেন্ট আছে — ছুঁলেই মৃত্যু।',
    icon: 'assets/safety/library/ppe/LOTO_Kit.webp'),
  DsPlanItem(id: 'hold', labelBn: 'আর্থ করো', letter: 'H',
    whyBn: 'ক্যাপাসিট্যান্স বা ভুল সুইচিং-এ ভোল্টেজ ফিরতে পারে — আর্থ সেটা মাটিতে পাঠায়।',
    icon: 'assets/safety/library/ppe/Portable_Earth_Rod.webp'),
  DsPlanItem(id: 'ok', labelBn: 'ফিতে ঘেরো', letter: 'O',
    whyBn: 'সাধারণ মানুষ বিপদ বোঝে না — ব্যারিকেড না দিলে ঢুকে পড়বে।',
    icon: 'assets/safety/library/ppe/Traffic_Cone_with_Chain.webp'),
  DsPlanItem(id: 'mend', labelBn: 'কাজ সারো', letter: 'M',
    whyBn: 'আগের সব ধাপ শেষ — এবার নিরাপদে কাজ করুন।',
    icon: 'assets/safety/library/tools/Insulated_Hand_Tools_Set.webp'),
  DsPlanItem(id: 'exit', labelBn: 'গুনে ফিরো', letter: 'E',
    whyBn: 'কেউ উপরে থাকলে লাইন চালু করলে সে মারা যাবে। সবাইকে গুনে নামান।',
    icon: 'assets/zero_loss/crew/rafiq.webp'),
];

class DsJobGroup {
  final String title;
  final int start;
  final int count;
  const DsJobGroup(this.title, this.start, this.count);
}

const dsJobGroups = <DsJobGroup>[
  DsJobGroup('কাজে যাবার আগে', 0, 4),
  DsJobGroup('মাঠে গিয়ে শুরুর আগে', 4, 6),
  DsJobGroup('কাজ শুরু', 10, 5),
  DsJobGroup('কাজের সময়', 15, 2),
  DsJobGroup('কাজের শেষে', 17, 6),
];

String dsJobHint(int number) => switch (number) {
      23 => 'এবার দুটো অপশন। 23 ধাপের মধ্যে এখন যেটা সঠিক, শুধু সেটাই ছুঁবেন।',
      24 => 'এবার চারটে অপশন। ক্রম মনে রেখে সঠিকটা নিন।',
      25 => 'এবার ছয়টা অপশন। কাছাকাছি নামে ধোঁকা খাবেন না।',
      26 => 'এবার দশটা অপশন। ধাপ এড়িয়ে গেলে বিপদ।',
      27 => 'এবার তেইশটাই সামনে। শুরু থেকে গোনা পর্যন্ত মনে রাখুন।',
      28 => 'এবার দুটো অপশন। ভুল ছুঁলেই কার্ড পাল্টে যাবে।',
      29 => 'এবার চারটে অপশন, আর ভুল হলেই সাজ বদলাবে।',
      30 => 'এবার ছয়টা অপশন, জীবন্ত। মন্ত্রটা মনে রেখে হাত বাড়ান।',
      31 => 'এবার দশটা অপশন, জীবন্ত। স্থির থেকে সঠিক ধাপ নিন।',
      _ => 'এবার তেইশটাই সামনে, আর ভুল ছুঁলেই নতুন সাজ।',
    };

class DsBrief {
  final String title;
  final String body;
  final List<String> stamps;
  const DsBrief({required this.title, required this.body, this.stamps = const []});
}

DsBrief dsBriefFor(DsLevelSpec spec) {
  const home = [
    'থামো ও বিপদ খুঁজো',
    'কবচ পরো',
    'পারমিট নাও',
    'দুদিক কাটো',
    'আর্থ করো',
    'ফিতে ঘেরো',
    'কাজ সারো',
    'গুনে ফিরো',
  ];
  if (spec.isField) {
    return const DsBrief(
      title: 'এটা আসল ডিউটি',
      body: 'ডকেট, শাটডাউন, পিপিই আর টুল — মাঠে নামার আগে সব ঠিক আছে কিনা দেখে নিন।',
      stamps: ['ডকেট', 'শাটডাউন', 'পিপিই', 'টুল'],
    );
  }
  if (spec.isLetters) {
    final title = switch (spec.number) {
      1 => 'পোশাক',
      2 => 'মাথায় হেলমেট',
      3 => 'হাতে গ্লাভস',
      4 => 'হারনেস',
      5 => 'পুরো কিট',
      6 => 'ভ্যান সাজান',
      7 => 'খুঁটিতে ওঠা',
      8 => 'ট্রান্সফরমার মৃত করা',
      9 => 'রাতের লাইনে ফল্ট',
      10 => 'ডাল লাইনের উপর',
      11 => 'পোলের ভাষা',
      12 => 'ফাঁপা পোল',
      13 => 'স্টিল পোল',
      14 => 'লক্ষ্মণ রেখা',
      15 => 'প্রধান ও প্রথম কথা',
      16 => 'আট ধাপ — আট মন্ত্র',
      17 => 'নিয়মের শর্টকাট মানেই মৃত্যু',
      18 => 'কোন ধাপ বাদ দিলে বাড়ি ফেরা হবে না',
      19 => 'তাড়াহুড়োই আসল শত্রু',
      20 => 'এক ভুল মানে একবার মৃত্যু',
      21 => 'ক্রম ভাঙলেই মৃত্যুর ভয়',
      22 => 'নিয়ম ছাড়া কাজে হাত নয়',
      _ => 'আট ধাপ — আট মন্ত্র',
    };
    final body = switch (spec.number) {
      1 => 'লাইনে কাজে নামার সময় আপনার পোশাকই প্রথম বর্ম। শরীরকে সম্পূর্ণ সুরক্ষিত রাখুন।',
      2 => 'মাথার সুরক্ষায় কোনো ছাড় নেই। ওপর থেকে পড়া বস্তু ও বিদ্যুৎস্পর্শ থেকে মাথাকে অক্ষত রাখুন।',
      3 => 'লাইনে কাজ করার সময় হাতই প্রথম ঝুঁকির মুখে পড়ে। লাইভ তার স্পর্শের আগে হাতের সুরক্ষা নিশ্চিত করুন।',
      4 => 'উচ্চতায় কাজের সময় পতন রোধে ফুল বডি হারনেসই জীবন বাঁচায়। সঠিক পদ্ধতিতে প্রতিটি বাকল লক করুন।',
      5 => 'এবার দ্রুত কাজের জন্য তৈরি হয়ে যান।',
      6 => 'কন্ট্রোল রুম থেকে জরুরি কাজের আদেশ এসেছে। সুরক্ষার নিয়ম মেনে দ্রুত তৈরি হয়ে নিন।',
      7 => 'বাজারের গলিতে তার ছিঁড়ে মাটিতে পড়ে আছে। পোল বেয়ে ওঠার জন্য এফআরপি মই আর হাত-দড়ি সঙ্গে নিন।',
      8 => 'ডিস্ট্রিবিউশন ট্রান্সফরমারে ফল্ট হয়েছে। বুশিং খোলার আগে তালা ও সতর্কবার্তা বোর্ড সঙ্গে নিন।',
      9 => 'মাঝরাতে রাস্তায় জরুরি ফল্ট ব্রেকডাউন। আলো নেই, দ্রুতগতিতে গাড়ি চলছে—টর্চ, ট্রাফিক কোন এবং রিফ্লেক্টিভ জ্যাকেট সঙ্গে নিন।',
      10 => 'ঝড়ে গাছের ডাল লাইনের ওপর ভেঙে পড়েছে। লাইন ডি-এনার্জাইজ করে ডাল সরানোর জন্য শক্ত হাত-দড়ি সঙ্গে নিন।',
      11 => 'পিপিই, শাটডাউন আর দুপাশে আর্থিং শেষ। এবার পোলে ওঠার আগের চেকগুলো করুন।',
      12 => 'পোল বাইরে সোজা দেখালেও ওঠার আগে হাতুড়ি দিয়ে পরীক্ষা করে নিন।',
      13 => 'স্টিল পোলে জাম্পার মেরামত। স্টিল ভাঙে না ভেবে না দেখে উঠবেন না—গোড়ার মরিচা চেক করুন।',
      14 => 'রাস্তার ধারে পোল, পাশে লোকজনের ভিড় ও বাড়ি। কাজ শুরুর আগে নিজের ও সাধারণ মানুষের সুরক্ষার লক্ষ্মণ রেখা তৈরি করুন।',
      15 => 'এবার দুটো অপশন। আট মন্ত্রের মধ্যে এখন যেটা সঠিক, শুধু সেটাই ছুঁবেন।',
      16 => 'এবার চারটে অপশন। ক্রম মনে রেখে সঠিকটা নিন।',
      17 => 'এবার ছয়টা অপশন। কাছাকাছি নামে ধোঁকা খাবেন না।',
      18 => 'এবার আটটাই সামনে। শুরু থেকে গোনা পর্যন্ত মনে রাখুন।',
      19 => 'এবার দুটো অপশন। ভুল ছুঁলেই কার্ড পাল্টে যাবে।',
      20 => 'এবার চারটে অপশন, আর ভুল হলেই সাজ বদলাবে। তাড়াহুড়ো নয়, সঠিক ধাপটা ধরে রাখুন।',
      21 => 'এবার ছয়টা অপশন, আর ভুল ছুঁলেই নতুন ফাঁদ। মন্ত্রটা মনে রেখে হাত বাড়ান।',
      22 => 'এবার আটটাই সামনে, আর ভুল ছুঁলেই নতুন সাজ। পুরো আট মন্ত্র মাথায় রেখে শেষ পর্যন্ত চলুন।',
      _ => 'এবার আটটাই সামনে, আর ভুল ছুঁলেই নতুন সাজ। পুরো আট মন্ত্র মাথায় রেখে শেষ পর্যন্ত চলুন।',
    };
    return DsBrief(title: enDigits(title), body: enDigits(body), stamps: home);
  }
  return DsBrief(
    title: 'আসল কাজ',
    body: enDigits(dsJobHint(spec.number)),
  );
}

/// One snapped-conductor night: levels → desk → site → close-out.
class DutySlipEngine {
  final DsPack pack;
  final Random _rng;

  late DsSite site;
  late String feeder;
  late List<String> fakes;
  late List<DsPlanItem> tonightPlan;
  late List<DsCall> siteCalls;

  var act = DsAct.briefing;
  var planPhase = DsPlanPhase.cover;
  var briefingPage = 0;
  var stepIndex = 0;
  var jobSeconds = 0;
  var safety = 100;
  var quality = 0;
  var hardMiss = false;
  var overtime = false;
  String? lethalReason;
  DsCall? activeCall;

  final stamps = <String>{};
  final slashed = <String>{};
  final rightSteps = <String>[];
  final wrongSteps = <String>[];
  var callsOk = 0;
  var callsBad = 0;
  var _cardsSinceCall = 0;
  var _callsFired = 0;
  var planNext = 0;
  var easyChoices = <DsPlanItem>[];
  var poolStamp = 0;

  var levelIndex = 0;
  var unlocked = 0;

  /// The ladder index the map opens at once (Home's gift chip); null: the
  /// current rung. The map reads it on its first pin and clears it.
  int? ladderAnchor;
  var nightTotal = 0;

  /// [nightTotal] when the field night started; the night's own score is
  /// [quality] minus this.
  var _fieldBase = 0;
  var levelScore = 0;
  var wrongTaps = 0;
  var streak = 0;
  final bestRank = List<DsLevelRank?>.filled(dsLevels.length, null);
  final bestDarunSec = List<int?>.filled(dsLevels.length, null);
  final levelDangerCount = List<int?>.filled(dsLevels.length, null);
  final levelBestScore = List<int>.filled(dsLevels.length, 0);

  int get totalCumulativeScore {
    var sum = 0;
    for (final s in levelBestScore) {
      sum += s;
    }
    return sum > 0 ? sum : nightTotal;
  }

  DutySlipEngine(this.pack, {int? seed}) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    site = pack.sites[_rng.nextInt(pack.sites.length)];
    final names = [...pack.feeders]..shuffle(_rng);
    feeder = names.first;
    fakes = names.skip(1).take(3).toList();
    tonightPlan = List<DsPlanItem>.from(pack.plan);
    if (dsPlayAllLevels) unlocked = dsLevels.length - 1;
    if (site.calls.isEmpty) {
      siteCalls = List<DsCall>.from(pack.calls);
    } else {
      final want = site.calls.toSet();
      siteCalls = [for (final c in pack.calls) if (want.contains(c.id)) c];
      if (siteCalls.isEmpty) siteCalls = List<DsCall>.from(pack.calls);
    }
  }

  DsStep? get step => stepIndex < pack.steps.length ? pack.steps[stepIndex] : null;
  int get totalSteps => pack.steps.length;
  int get clockHour {
    final t = pack.startHour * 3600 + pack.startMinute * 60 + jobSeconds;
    return (t ~/ 3600) % 24;
  }

  int get clockMinute => ((pack.startHour * 3600 + pack.startMinute * 60 + jobSeconds) % 3600) ~/ 60;

  String get clockLabel {
    final h = clockHour.toString().padLeft(2, '0');
    final m = clockMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DsLevelSpec get level => dsLevels[levelIndex.clamp(0, dsLevels.length - 1)];
  DsBrief briefOf([DsLevelSpec? spec]) => dsBriefFor(spec ?? level);

  List<DsPlanItem> get currentDeck => level.isLetters ? dsSafeHome : tonightPlan;
  int get choiceCount {
    final n = level.choices;
    return n <= 0 ? currentDeck.length : min(n, currentDeck.length);
  }

  bool get planning => act == DsAct.briefing && briefingPage == 0;
  bool get covering => planning && planPhase == DsPlanPhase.cover;
  bool get onRoad => planning && planPhase == DsPlanPhase.road;
  bool get listing => planning && planPhase == DsPlanPhase.list;
  var dressArmed = false;
  var dressOpen = false;
  bool get dressLevel => level.isLetters && level.number <= 14;
  bool get showingDressIntro => listing && dressLevel && !dressOpen;
  bool get showingDress => listing && dressLevel && dressOpen;

  void openDress() {
    if (!showingDressIntro) return;
    dressOpen = true;
  }

  void beginDress() {
    if (!showingDress || dressArmed) return;
    dressArmed = true;
    levelScore = 0;
    wrongTaps = 0;
    streak = 0;
    _armClock();
  }

  void dressRight() {
    if (!showingDress || !dressArmed) return;
    streak++;
    levelScore += 5;
  }

  void dressWrong() {
    if (!showingDress || !dressArmed) return;
    streak = 0;
    wrongTaps++;
    levelScore -= 5;
    safety = max(0, safety - 5);
  }

  void finishDress() {
    if (!showingDress) return;
    _finishPlan();
  }
  bool get playing => planning && planPhase == DsPlanPhase.play;
  bool get showingResult => planning && planPhase == DsPlanPhase.result;
  bool get prePlay => covering || onRoad || listing || showingResult;
  bool get showHud => playing || listing || !planning;

  var clockLive = false;
  var playSeconds = 0;
  var _playAcc = 0;

  int get hudTotal => (playing || showingDress) ? nightTotal + levelScore : nightTotal;

  DsLevelRank get levelRank {
    final deck = currentDeck.length;
    final maxWrong = deck <= 8 ? 2 : 7;
    final darunWrong = deck <= 8 ? 1 : 3;
    if (wrongTaps > maxWrong) return DsLevelRank.again;
    if (wrongTaps <= darunWrong && playSeconds <= level.darunSec) return DsLevelRank.darun;
    if (wrongTaps <= maxWrong) return DsLevelRank.motamuti;
    return DsLevelRank.again;
  }

  void addJobSeconds(int sec) {
    if (act == DsAct.done || act == DsAct.lethal || prePlay || playing) return;
    jobSeconds += sec;
    if (jobSeconds >= 2 * 3600 + 20 * 60) overtime = true;
  }

  /// True while [tickPlay] counts (the level's mm:ss clock is running).
  bool get playClockRuns {
    if (!clockLive || showingResult || act == DsAct.done || act == DsAct.lethal) return false;
    return playing || showingDress || !planning;
  }

  /// True while the page should drive the clocks at all: a level or job act
  /// is on screen. Does not depend on [clockLive], which games arm themselves.
  bool get clockScreen {
    if (act == DsAct.done || act == DsAct.lethal) return false;
    return playing || showingDress || !planning;
  }

  /// Milliseconds of play time left before [playSeconds] goes up next.
  int get playMsToNextSecond => 1000 - _playAcc;

  void tickPlay(int millis) {
    if (!playClockRuns) return;
    _playAcc += millis;
    while (_playAcc >= 1000) {
      _playAcc -= 1000;
      playSeconds++;
    }
  }

  String get playClock => formatClock(playSeconds);

  String formatClock(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void jumpMinutes(int min) {
    jobSeconds += min * 60;
    if (jobSeconds >= 2 * 3600 + 20 * 60) overtime = true;
  }

  void addScore(int delta) {
    quality += delta;
  }

  String fill(String raw) => enDigits(
        raw
            .replaceAll('{{feeder}}', feeder)
            .replaceAll('{{fake1}}', fakes.isNotEmpty ? fakes[0] : 'রামপুর কলোনি-11')
            .replaceAll('{{fake2}}', fakes.length > 1 ? fakes[1] : 'হাটতলা-11')
            .replaceAll('{{pole}}', site.pole)
            .replaceAll('{{site}}', site.nameBn),
      );

  String optionLabel(DsOption o) {
    final baked = fill(o.labelBn);
    if (baked.isNotEmpty) return baked;
    return switch (o.id) {
      'true' => enDigits(feeder),
      'fake1' => enDigits(fakes.isNotEmpty ? fakes[0] : 'রামপুর কলোনি-11'),
      'fake2' => enDigits(fakes.length > 1 ? fakes[1] : 'হাটতলা-11'),
      'fake3' => enDigits(fakes.length > 2 ? fakes[2] : 'পুরাতন রামপুর-11'),
      _ => enDigits(o.labelBn),
    };
  }

  void openRoad() {
    if (planPhase != DsPlanPhase.cover && planPhase != DsPlanPhase.list && planPhase != DsPlanPhase.result) return;
    clockLive = false;
    planPhase = DsPlanPhase.road;
  }

  /// True while the level on screen was opened from the catalog ladder. The
  /// ladder unlocks by saved rung ids then, and [unlocked] (a ladder index)
  /// must not jump to this level's own `dsLevels` index.
  var openedFromLadder = false;

  void openLevel(int index, {bool fromLadder = false}) {
    if (!onRoad) return;
    if (index < 0 || index >= dsLevels.length) return;
    // The ladder already checked its own lock; a rung may open a later level by topic.
    if (!fromLadder && !dsPlayAllLevels && index > unlocked) return;
    openedFromLadder = fromLadder;
    levelIndex = index;
    dressArmed = false;
    dressOpen = dsLevels[index].number == 6;
    planPhase = DsPlanPhase.list;
  }

  /// After a catalog Learn clear — open the next bridge index without finishing a Do.
  void unlockThrough(int index) {
    if (dsPlayAllLevels) return;
    final next = index.clamp(0, dsLevels.length - 1);
    if (next > unlocked) {
      unlocked = next;
      unawaited(savePersistedState());
    }
  }

  void backToRoad() {
    if (inField) {
      leaveField();
      return;
    }
    if (planPhase != DsPlanPhase.list && planPhase != DsPlanPhase.result) return;
    clockLive = false;
    dressArmed = false;
    dressOpen = false;
    planPhase = DsPlanPhase.road;
  }

  /// True once the field night has left the level list (docket, PTW, cards,
  /// calls or the report are on screen).
  bool get inField => level.isField && (act != DsAct.briefing || briefingPage != 0);

  /// The field night's own score so far (what it adds to the career total).
  int get fieldEarned => max(0, quality - _fieldBase);

  /// Leave the field night for the ladder. Drops the unfinished night; a
  /// finished night's score was already recorded by [_finishField].
  void leaveField() {
    if (!inField) return;
    _resetFieldRun();
    clockLive = false;
    dressArmed = false;
    dressOpen = false;
    quality = nightTotal;
    planPhase = DsPlanPhase.road;
  }

  void _resetFieldRun() {
    act = DsAct.briefing;
    briefingPage = 0;
    stepIndex = 0;
    stamps.clear();
    slashed.clear();
    rightSteps.clear();
    wrongSteps.clear();
    callsOk = 0;
    callsBad = 0;
    _callsFired = 0;
    _cardsSinceCall = 0;
    activeCall = null;
    lethalReason = null;
    safety = 100;
    jobSeconds = 0;
    hardMiss = false;
    overtime = false;
  }

  static const _maxCalls = 3;

  /// Most a field night can score: +5 per single/match card, +5 per kit item
  /// (yes/no taps), +5 per call (at most [_maxCalls] fire) and +5 for the PTW.
  int get fieldMaxScore {
    var n = 5;
    for (final s in pack.steps) {
      n += s.kind == DsKind.kit ? 5 * s.options.length : 5;
    }
    if (pack.calls.isNotEmpty) n += 5 * _maxCalls;
    return n;
  }

  /// Most one run of level [index] can score, or null when the level's own
  /// game decides (the dress and photo levels 1-14).
  int? levelMaxScore(int index) {
    final spec = dsLevels[index];
    if (spec.isField) return fieldMaxScore;
    if (spec.isLetters && spec.number <= 14) return null;
    final n = spec.isLetters ? dsSafeHome.length : tonightPlan.length;
    return 5 * n + 5 * (n ~/ 6);
  }

  /// Lethal fall: rewind unlock to the first level of the current 20-level module.
  void fallToModuleCheckpoint() {
    _resetFieldRun();
    final start = (levelIndex ~/ 20) * 20;
    unlocked = start.clamp(0, unlocked);
    levelIndex = start;
    clockLive = false;
    dressArmed = false;
    dressOpen = false;
    planPhase = DsPlanPhase.road;
    act = DsAct.briefing;
    unawaited(savePersistedState());
  }

  void startLevelPlay() {
    if (planPhase != DsPlanPhase.list) return;
    if (level.isField) {
      _resetFieldRun();
      _fieldBase = nightTotal;
      quality = nightTotal;
      stamps.add('assign');
      briefingPage = 1;
      _armClock();
      return;
    }
    planPhase = DsPlanPhase.play;
    planNext = 0;
    levelScore = 0;
    wrongTaps = 0;
    streak = 0;
    easyChoices = [];
    _armClock();
    _rebuildChoices();
  }

  void replayNow() {
    if (planPhase != DsPlanPhase.result) return;
    dressArmed = false;
    levelScore = 0;
    wrongTaps = 0;
    streak = 0;
    planPhase = DsPlanPhase.list;
    if (level.isLetters && level.number <= 14) {
      clockLive = false;
      dressOpen = level.number == 6;
      return;
    }
    dressOpen = false;
    startLevelPlay();
  }

  void nextAfterPass() {
    if (planPhase != DsPlanPhase.result) return;
    if (levelRank == DsLevelRank.again) return;
    clockLive = false;
    dressOpen = false;
    planPhase = DsPlanPhase.road;
  }

  void _armClock() {
    clockLive = true;
    playSeconds = 0;
    _playAcc = 0;
  }

  void _rebuildChoices({Set<String>? avoid}) {
    final deck = currentDeck;
    if (planNext >= deck.length) {
      easyChoices = [];
      poolStamp++;
      return;
    }
    final correct = deck[planNext];
    bool far(int i) => (i - planNext).abs() > 1;
    final farOnes = <DsPlanItem>[
      for (var i = 0; i < deck.length; i++)
        if (i != planNext && far(i)) deck[i],
    ]..shuffle(_rng);
    final nearOnes = <DsPlanItem>[
      for (var i = 0; i < deck.length; i++)
        if (i != planNext && !far(i)) deck[i],
    ]..shuffle(_rng);
    var pool = farOnes.isNotEmpty ? [...farOnes, ...nearOnes] : [...nearOnes];
    if (avoid != null && avoid.isNotEmpty) {
      final fresh = pool.where((p) => !avoid.contains(p.id)).toList();
      if (fresh.isNotEmpty) {
        final stale = pool.where((p) => avoid.contains(p.id)).toList();
        pool = [...fresh, ...stale];
      }
    }
    final take = min(choiceCount - 1, pool.length);
    easyChoices = [correct, ...pool.take(take)]..shuffle(_rng);
    poolStamp++;
  }

  void _finishPlan() {
    clockLive = false;
    planPhase = DsPlanPhase.result;

    final earnedScore = max(0, levelScore);
    final scoreImproved = earnedScore > levelBestScore[levelIndex];
    if (levelRank != DsLevelRank.again && scoreImproved) {
      levelBestScore[levelIndex] = earnedScore;
    }

    final prev = bestRank[levelIndex];
    final rankImproved = prev == null || _rankWeight(levelRank) > _rankWeight(prev);
    if (rankImproved) {
      bestRank[levelIndex] = levelRank;
    }

    final old = bestDarunSec[levelIndex];
    if (levelRank != DsLevelRank.again && (old == null || (playSeconds > 0 && playSeconds < old))) {
      bestDarunSec[levelIndex] = playSeconds;
    }

    // Danger count: record danger for this level run.
    final curDanger = levelDangerCount[levelIndex];
    if (curDanger == null || prev == null || prev == DsLevelRank.again || rankImproved || scoreImproved || wrongTaps < curDanger) {
      levelDangerCount[levelIndex] = wrongTaps;
    }

    // Advance unlock if achieved motamuti or darun (ladder-opened levels unlock by rung id).
    if (levelRank != DsLevelRank.again && !openedFromLadder) {
      if (levelIndex + 1 > unlocked) {
        unlocked = min(levelIndex + 1, dsLevels.length - 1);
      }
    }

    nightTotal = totalCumulativeScore;
    quality = nightTotal;

    unawaited(savePersistedState());
  }

  /// Progress is saved by level number, never by list position (GAME_DESIGN
  /// §6), so adding or moving levels cannot shift it onto other levels.
  static const progressKey = 'ds_progress_v2';
  static const _legacyKeys = [
    'ds_unlocked_level',
    'ds_best_ranks',
    'ds_best_times',
    'ds_danger_counts',
    'ds_best_scores',
  ];

  /// Level numbers of the 19-level ladder saved before 2026-10-29, by index.
  /// Levels 1-11 kept their numbers; old 12-19 (the two plain jobs, the five
  /// living jobs and the field night) are now 26-33.
  static const legacy19Numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 26, 27, 28, 29, 30, 31, 32, 33];

  static int? _indexOfNumber(int number) {
    for (var i = 0; i < dsLevels.length; i++) {
      if (dsLevels[i].number == number) return i;
    }
    return null;
  }

  static DsLevelRank? _rankFrom(Object? raw) => switch (raw) {
        'darun' => DsLevelRank.darun,
        'motamuti' => DsLevelRank.motamuti,
        'again' => DsLevelRank.again,
        _ => null,
      };

  Future<void> loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedScore = prefs.getInt('ds_career_score');
      if (savedScore != null && savedScore > 0) {
        nightTotal = savedScore;
        quality = savedScore;
      }
      var dirty = false;
      final raw = prefs.getString(progressKey);
      if (raw != null && raw.isNotEmpty) {
        _readProgress(jsonDecode(raw) as Map<String, dynamic>);
      } else if (_legacyKeys.any(prefs.containsKey)) {
        _readLegacyLists(prefs);
        dirty = true;
      }
      // One-time repair: older builds stored (every other level + the night)
      // in the field slot and it grew on each replay; an index-based load
      // could also move that number onto level 19. No run can beat the max.
      var repaired = false;
      for (var i = 0; i < dsLevels.length; i++) {
        final cap = levelMaxScore(i);
        if (cap != null && levelBestScore[i] > cap) {
          levelBestScore[i] = cap;
          repaired = true;
        }
      }
      if (repaired) {
        nightTotal = totalCumulativeScore;
        quality = nightTotal;
        dirty = true;
      }
      if (dirty) {
        await savePersistedState();
        for (final k in _legacyKeys) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}
  }

  /// [unlocked] for a saved level number: the last level at or below it.
  static int unlockedIndexOf(int levelNumber) {
    var idx = 0;
    for (var i = 0; i < dsLevels.length; i++) {
      if (dsLevels[i].number <= levelNumber) idx = i;
    }
    return idx;
  }

  /// The saved [unlocked] without building an engine (Home reads it to name
  /// the next rung the ladder will open on). 0 when nothing is saved.
  static Future<int> savedUnlocked() async {
    if (dsPlayAllLevels) return dsLevels.length - 1;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(progressKey);
      if (raw == null || raw.isEmpty) return 0;
      final no = ((jsonDecode(raw) as Map<String, dynamic>)['unlocked'] as num?)?.toInt();
      return no == null ? 0 : unlockedIndexOf(no);
    } catch (_) {
      return 0;
    }
  }

  void _readProgress(Map<String, dynamic> json) {
    final unlockedNo = (json['unlocked'] as num?)?.toInt();
    if (unlockedNo != null && !dsPlayAllLevels) {
      unlocked = unlockedIndexOf(unlockedNo);
    }
    final levels = json['levels'];
    if (levels is! Map) return;
    for (final entry in levels.entries) {
      final i = _indexOfNumber(int.tryParse('${entry.key}') ?? -1);
      final v = entry.value;
      if (i == null || v is! Map) continue;
      bestRank[i] = _rankFrom(v['rank']);
      final t = (v['time'] as num?)?.toInt();
      if (t != null && t > 0) bestDarunSec[i] = t;
      final d = (v['danger'] as num?)?.toInt();
      if (d != null && d >= 0 && bestRank[i] != null) levelDangerCount[i] = d;
      final sc = (v['score'] as num?)?.toInt();
      if (sc != null) levelBestScore[i] = sc;
    }
  }

  /// Old saves: positional string lists. 19-long lists are the pre-2026-10-29
  /// ladder; any other length was written by the current ladder.
  void _readLegacyLists(SharedPreferences prefs) {
    final ranksRaw = prefs.getStringList('ds_best_ranks');
    final timesRaw = prefs.getStringList('ds_best_times');
    final dangerRaw = prefs.getStringList('ds_danger_counts');
    final scoresRaw = prefs.getStringList('ds_best_scores');
    final lengths = [ranksRaw, timesRaw, dangerRaw, scoresRaw].whereType<List<String>>().map((l) => l.length);
    final old19 = dsLevels.length != legacy19Numbers.length &&
        lengths.isNotEmpty &&
        lengths.every((n) => n == legacy19Numbers.length);
    int? target(int oldIndex) {
      if (!old19) return oldIndex < dsLevels.length ? oldIndex : null;
      if (oldIndex >= legacy19Numbers.length) return null;
      return _indexOfNumber(legacy19Numbers[oldIndex]);
    }

    final savedUnlocked = prefs.getInt('ds_unlocked_level');
    if (savedUnlocked != null && !dsPlayAllLevels) {
      final top = (old19 ? legacy19Numbers.length : dsLevels.length) - 1;
      final u = target(savedUnlocked.clamp(0, top));
      if (u != null) unlocked = u;
    }
    if (ranksRaw != null) {
      for (var i = 0; i < ranksRaw.length; i++) {
        final j = target(i);
        final r = _rankFrom(ranksRaw[i]);
        if (j != null && r != null) bestRank[j] = r;
      }
    }
    if (timesRaw != null) {
      for (var i = 0; i < timesRaw.length; i++) {
        final j = target(i);
        final t = int.tryParse(timesRaw[i]);
        if (j != null && t != null && t > 0) bestDarunSec[j] = t;
      }
    }
    if (dangerRaw != null) {
      for (var i = 0; i < dangerRaw.length; i++) {
        final j = target(i);
        final d = int.tryParse(dangerRaw[i]);
        // Only attribute danger if the level has a recorded rank / was played.
        if (j != null && d != null && d >= 0 && bestRank[j] != null) levelDangerCount[j] = d;
      }
    }
    if (scoresRaw != null) {
      for (var i = 0; i < scoresRaw.length; i++) {
        final j = target(i);
        final sc = int.tryParse(scoresRaw[i]);
        if (j != null && sc != null) levelBestScore[j] = sc;
      }
    }
  }

  /// The saved form of per-level progress, keyed by level number.
  Map<String, dynamic> progressJson() {
    final levels = <String, dynamic>{};
    for (var i = 0; i < dsLevels.length; i++) {
      final r = bestRank[i];
      final t = bestDarunSec[i];
      final d = levelDangerCount[i];
      final sc = levelBestScore[i];
      if (r == null && t == null && d == null && sc == 0) continue;
      levels['${dsLevels[i].number}'] = {
        if (r != null) 'rank': r.name,
        'time': ?t,
        'danger': ?d,
        if (sc != 0) 'score': sc,
      };
    }
    return {
      'v': 2,
      'unlocked': dsLevels[unlocked.clamp(0, dsLevels.length - 1)].number,
      'levels': levels,
    };
  }

  Future<void> savePersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ds_career_score', totalCumulativeScore);
      await prefs.setString(progressKey, jsonEncode(progressJson()));
      // Bridge: keep GameSave ◆ in sync until all beats write GameSave directly.
      await _mirrorCareerIntoGameSave(prefs, totalCumulativeScore);
    } catch (_) {}
  }

  Future<void> _mirrorCareerIntoGameSave(SharedPreferences prefs, int points) async {
    const key = 'game_save_v1';
    try {
      final raw = prefs.getString(key);
      Map<String, dynamic> json;
      if (raw != null && raw.isNotEmpty) {
        json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } else {
        json = {
          'seasonId': 'season-1',
          'points': 0,
          'deaths': 0,
          'safeStreak': 0,
          'rankIndex': 0,
          'currentRungId': '1.1/learn',
          'rungProgress': <String, String>{},
          'bestByRung': <String, int>{},
          'deathLog': <dynamic>[],
          'promises': <String>[],
          'ppeOwned': <String>[],
          'giftsClaimed': <String>[],
          'migratedFromDs': true,
        };
      }
      final prev = (json['points'] as num?)?.toInt() ?? 0;
      if (points > prev) json['points'] = points;
      json['migratedFromDs'] = true;
      await prefs.setString(key, jsonEncode(json));
    } catch (_) {}
  }

  int _rankWeight(DsLevelRank r) => switch (r) {
        DsLevelRank.darun => 3,
        DsLevelRank.motamuti => 2,
        DsLevelRank.again => 1,
      };

  DsResult tapPlan(String id) {
    if (planPhase != DsPlanPhase.play) return const DsResult(ok: false);
    final deck = currentDeck;
    if (planNext >= deck.length) return const DsResult(ok: true);
    if (id == deck[planNext].id) {
      planNext++;
      streak++;
      var delta = 5;
      var gift = false;
      if (streak > 0 && streak % 6 == 0) {
        delta += 5;
        gift = true;
      }
      levelScore += delta;
      if (planNext >= deck.length) {
        _finishPlan();
      } else {
        _rebuildChoices();
      }
      return DsResult(ok: true, delta: delta, streak: streak, gift: gift);
    }
    streak = 0;
    wrongTaps++;
    levelScore -= 5;
    safety = max(0, safety - 5);
    if (level.living) {
      final avoid = {
        for (final p in easyChoices)
          if (p.id != deck[planNext].id) p.id,
      };
      _rebuildChoices(avoid: avoid);
    }
    return const DsResult(ok: false, delta: -5);
  }

  void openPtw() {
    briefingPage = 2;
  }

  bool submitPtw({required String feederPick, required String polePick, required String shiftPick}) {
    final ok = feederPick == feeder && polePick == site.pole && shiftPick == 'আজ রাত';
    if (!ok) {
      safety = max(0, safety - 5);
      addScore(-5);
      hardMiss = hardMiss || feederPick != feeder;
      slashed.add('ptw');
      jumpMinutes(10);
      return false;
    }
    stamps.add('ptw');
    addScore(5);
    act = DsAct.card;
    return true;
  }

  DsResult answerSingle(String id) {
    final s = step;
    if (s == null) return const DsResult(ok: false);
    DsOption? opt;
    for (final o in s.options) {
      if (o.id == id) {
        opt = o;
        break;
      }
    }
    if (opt == null) return const DsResult(ok: false);
    if (opt.lethal) return _lethal(s, 'ভুল গেটে কাজ — আনসেফ ক্লোজ');
    final ok = s.kind == DsKind.match ? id == 'true' || opt.correct : opt.correct;
    return _apply(s, ok);
  }

  DsResult answerKit(Set<String> picked) {
    final s = step;
    if (s == null || s.kind != DsKind.kit) return const DsResult(ok: false);
    final ok = s.essential.every(picked.contains) && !s.forbidden.any(picked.contains) && picked.isNotEmpty;
    return _apply(s, ok, score: false);
  }

  DsResult _apply(DsStep s, bool ok, {bool score = true}) {
    if (ok) {
      if (score) addScore(5);
      rightSteps.add(s.id);
      if (s.stamp.isNotEmpty) stamps.add(s.stamp);
      _advance();
      return DsResult(ok: true, delta: score ? 5 : 0);
    }
    if (score) addScore(-5);
    safety = max(0, safety - 5);
    jumpMinutes(s.missMin);
    if (!wrongSteps.contains(s.id)) wrongSteps.add(s.id);
    if (s.missSafety >= 18) {
      hardMiss = true;
      if (s.stamp.isNotEmpty) slashed.add(s.stamp);
    }
    return DsResult(ok: false, delta: score ? -5 : 0);
  }

  DsResult _lethal(DsStep s, String reason) {
    addScore(-5);
    safety = 0;
    lethalReason = reason;
    act = DsAct.lethal;
    if (s.stamp.isNotEmpty) slashed.add(s.stamp);
    final fieldIndex = dsLevels.length - 1;
    final prev = bestRank[fieldIndex];
    if (prev == null) {
      bestRank[fieldIndex] = DsLevelRank.again;
    }
    final mistakes = callsBad + wrongSteps.length + 1;
    final cur = levelDangerCount[fieldIndex];
    if (cur == null || prev == null || prev == DsLevelRank.again || mistakes < cur) {
      levelDangerCount[fieldIndex] = cur == null ? mistakes : min(cur, mistakes);
    }
    unawaited(savePersistedState());
    return DsResult(ok: false, lethal: true, noteBn: reason, delta: -5);
  }

  void _finishField() {
    act = DsAct.done;
    final fieldIndex = dsLevels.length - 1;
    final fieldRank = switch (grade()) {
      DsGrade.safe => DsLevelRank.darun,
      DsGrade.risky => DsLevelRank.motamuti,
      DsGrade.unsafe => DsLevelRank.again,
    };
    final prev = bestRank[fieldIndex];
    final rankImproved = prev == null || _rankWeight(fieldRank) > _rankWeight(prev);
    if (rankImproved) {
      bestRank[fieldIndex] = fieldRank;
    }
    final mistakes = callsBad + wrongSteps.length + (hardMiss ? 1 : 0);
    final cur = levelDangerCount[fieldIndex];
    if (cur == null || prev == null || prev == DsLevelRank.again || rankImproved || mistakes < cur) {
      levelDangerCount[fieldIndex] = mistakes;
    }
    final oldTime = bestDarunSec[fieldIndex];
    if (oldTime == null || (jobSeconds > 0 && jobSeconds < oldTime)) {
      bestDarunSec[fieldIndex] = jobSeconds;
    }
    final earned = min(fieldEarned, fieldMaxScore);
    if (earned > levelBestScore[fieldIndex]) {
      levelBestScore[fieldIndex] = earned;
    }
    nightTotal = totalCumulativeScore;
    quality = nightTotal;
    unawaited(savePersistedState());
  }

  void _advance() {
    stepIndex++;
    _cardsSinceCall++;
    if (stepIndex >= pack.steps.length) {
      _finishField();
      return;
    }
    if (_maybeCall()) return;
    act = DsAct.card;
  }

  bool _maybeCall() {
    if (siteCalls.isEmpty || _callsFired >= _maxCalls) return false;
    if (!stamps.contains('site')) return false;
    if (_cardsSinceCall < 2) return false;
    if (_rng.nextDouble() > 0.4) return false;
    activeCall = siteCalls[_rng.nextInt(siteCalls.length)];
    act = DsAct.call;
    _cardsSinceCall = 0;
    _callsFired++;
    return true;
  }

  DsResult answerCall(String replyId) {
    final c = activeCall;
    if (c == null) return const DsResult(ok: false);
    DsReply? r;
    for (final x in c.replies) {
      if (x.id == replyId) {
        r = x;
        break;
      }
    }
    activeCall = null;
    if (r == null) {
      act = DsAct.card;
      return const DsResult(ok: false);
    }
    if (r.ok) {
      callsOk++;
      addScore(5);
      if (stepIndex >= pack.steps.length) {
        _finishField();
      } else {
        act = DsAct.card;
      }
      return const DsResult(ok: true, delta: 5);
    }
    callsBad++;
    addScore(-5);
    safety = max(0, safety - 5);
    jumpMinutes(10);
    hardMiss = true;
    if (stepIndex >= pack.steps.length) {
      _finishField();
    } else {
      act = DsAct.card;
    }
    return const DsResult(ok: false, delta: -5);
  }

  DsGrade grade() {
    if (act == DsAct.lethal || safety <= 0) return DsGrade.unsafe;
    if (!stamps.contains('ptw_back')) return DsGrade.unsafe;
    if (safety >= 85 && !hardMiss && !overtime) return DsGrade.safe;
    return DsGrade.risky;
  }

  String gradeBn() => switch (grade()) {
        DsGrade.safe => 'মিশন কমপ্লিট · সেফ',
        DsGrade.risky => 'মিশন কমপ্লিট · ঝুঁকি ছিল',
        DsGrade.unsafe => 'আনসেফ ক্লোজ',
      };
}
