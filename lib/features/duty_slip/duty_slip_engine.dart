import 'dart:math';

import 'duty_slip_models.dart';

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

/// Testing: every live plate is tappable. Set `false` to restore sequential unlock.
const dsAllLevelsOpen = true;

const dsLevels = <DsLevelSpec>[
  DsLevelSpec(number: 1, kind: DsLevelKind.letters, choices: 2, darunSec: 150),
  DsLevelSpec(number: 2, kind: DsLevelKind.letters, choices: 4, darunSec: 80),
  DsLevelSpec(number: 3, kind: DsLevelKind.letters, choices: 6, darunSec: 100),
  DsLevelSpec(number: 4, kind: DsLevelKind.letters, choices: 8, darunSec: 180),
  DsLevelSpec(number: 5, kind: DsLevelKind.letters, choices: 8, darunSec: 200),
  DsLevelSpec(number: 6, kind: DsLevelKind.letters, choices: 4, darunSec: 70, living: true),
  DsLevelSpec(number: 7, kind: DsLevelKind.letters, choices: 6, darunSec: 85, living: true),
  DsLevelSpec(number: 8, kind: DsLevelKind.letters, choices: 8, darunSec: 100, living: true),
  DsLevelSpec(number: 9, kind: DsLevelKind.job, choices: 2, darunSec: 75),
  DsLevelSpec(number: 10, kind: DsLevelKind.job, choices: 4, darunSec: 105),
  DsLevelSpec(number: 11, kind: DsLevelKind.job, choices: 6, darunSec: 150),
  DsLevelSpec(number: 12, kind: DsLevelKind.job, choices: 10, darunSec: 180),
  DsLevelSpec(number: 13, kind: DsLevelKind.job, choices: 23, darunSec: 240),
  DsLevelSpec(number: 14, kind: DsLevelKind.job, choices: 2, darunSec: 70, living: true),
  DsLevelSpec(number: 15, kind: DsLevelKind.job, choices: 4, darunSec: 95, living: true),
  DsLevelSpec(number: 16, kind: DsLevelKind.job, choices: 6, darunSec: 135, living: true),
  DsLevelSpec(number: 17, kind: DsLevelKind.job, choices: 10, darunSec: 160, living: true),
  DsLevelSpec(number: 18, kind: DsLevelKind.job, choices: 23, darunSec: 210, living: true),
  DsLevelSpec(number: 19, kind: DsLevelKind.field, choices: 0, darunSec: 0),
];

const dsSafeHome = <DsPlanItem>[
  DsPlanItem(id: 'stop', labelBn: 'থামো ও বিপদ খুঁজো', letter: 'S',
    whyBn: 'তাড়াহুড়ো করলে বিপদ দেখা যায় না। দাঁড়িয়ে চারদিক দেখুন।',
    icon: 'assets/safety/library/ppe/High_Visibility_Vest_3.webp'),
  DsPlanItem(id: 'armour', labelBn: 'কবচ পরো', letter: 'A',
    whyBn: 'PPE ছাড়া লাইনে হাত দিলে শক, পোড়া, পড়ে যাওয়া — তিনটাই হয়।',
    icon: 'assets/safety/library/ppe/Safety_Helmet.webp'),
  DsPlanItem(id: 'form', labelBn: 'পারমিট নাও', letter: 'F',
    whyBn: 'PTW ছাড়া কেউ জানে না আপনি লাইনে — যে কোনো সময় চালু করতে পারে।',
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

const dsSafeHomeWord = 'SAFE HOME';

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
      9 => 'এবার দুটো অপশন। ২৩ ধাপের মধ্যে এখন যেটা সঠিক, শুধু সেটাই ছুঁবেন।',
      10 => 'এবার চারটে অপশন। ক্রম মনে রেখে সঠিকটা নিন।',
      11 => 'এবার ছয়টা অপশন। কাছাকাছি নামে ধোঁকা খাবেন না।',
      12 => 'এবার দশটা অপশন। ধাপ এড়িয়ে গেলে বিপদ।',
      13 => 'এবার তেইশটাই সামনে। শুরু থেকে গোনা পর্যন্ত মনে রাখুন।',
      14 => 'এবার দুটো অপশন। ভুল ছুঁলেই কার্ড পাল্টে যাবে।',
      15 => 'এবার চারটে অপশন, আর ভুল হলেই সাজ বদলাবে।',
      16 => 'এবার ছয়টা অপশন, জীবন্ত। মন্ত্রটা মনে রেখে হাত বাড়ান।',
      17 => 'এবার দশটা অপশন, জীবন্ত। স্থির থেকে সঠিক ধাপ নিন।',
      _ => 'এবার তেইশটাই সামনে, আর ভুল ছুঁলেই নতুন সাজ।',
    };

class DsBrief {
  final String title;
  final String body;
  final List<String> stamps;
  const DsBrief({required this.title, required this.body, this.stamps = const []});
}

const dsLetterTitlePool = [
  'আট ধাপ — আট মন্ত্র',
  'নিয়মের শর্টকাট মানেই মৃত্যু',
  'কোন ধাপ বাদ দিলে বাড়ি ফেরা হবে না',
  'তাড়াহুড়োই আসল শত্রু',
  'এক ভুল মানে একবার মৃত্যু',
  'ক্রম ভাঙলেই মৃত্যুর ভয়',
  'নিয়ম ছাড়া কাজে হাত নয়',
];

DsBrief dsBriefFor(DsLevelSpec spec, {String? letterTitle}) {
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
      _ => letterTitle ?? dsLetterTitlePool.first,
    };
    final body = switch (spec.number) {
      1 => 'সঠিক পোশাকই নিরাপত্তার প্রথম ধাপ।',
      2 => 'এবার সঠিক হেলমেট চিনে নিন ও ঠিকভাবে পরে ফেলুন।',
      3 => 'এবার সঠিক গ্লাভস চিনে নিন ও হাতে ঠিকভাবে পরে ফেলুন।',
      4 => 'এবার সঠিক হারনেস চিনে নিন ও গায়ে ঠিকভাবে বেঁধে ফেলুন।',
      5 => 'এবার দ্রুত কাজের জন্য তৈরি হয়ে যান।',
      6 => 'এবার চারটে অপশন, আর ভুল হলেই সাজ বদলাবে। তাড়াহুড়ো নয়, সঠিক ধাপটা ধরে রাখুন।',
      7 => 'এবার ছয়টা অপশন, আর ভুল ছুঁলেই নতুন ফাঁদ। মন্ত্রটা মনে রেখে হাত বাড়ান।',
      _ => 'এবার আটটাই সামনে, আর ভুল ছুঁলেই নতুন সাজ। পুরো আট মন্ত্র মাথায় রেখে শেষ পর্যন্ত চলুন।',
    };
    return DsBrief(title: title, body: body, stamps: home);
  }
  return DsBrief(
    title: 'আসল কাজ',
    body: dsJobHint(spec.number),
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
  late List<DsPlanItem> planPool;
  var easyChoices = <DsPlanItem>[];
  var poolStamp = 0;

  var levelIndex = 0;
  var unlocked = 0;
  var nightTotal = 0;
  var levelScore = 0;
  var wrongTaps = 0;
  var streak = 0;
  final bestRank = List<DsLevelRank?>.filled(dsLevels.length, null);
  final bestDarunSec = List<int?>.filled(dsLevels.length, null);
  late final List<String> _letterTitles;

  DutySlipEngine(this.pack, {int? seed}) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    site = pack.sites[_rng.nextInt(pack.sites.length)];
    final names = [...pack.feeders]..shuffle(_rng);
    feeder = names.first;
    fakes = names.skip(1).take(3).toList();
    tonightPlan = List<DsPlanItem>.from(pack.plan);
    planPool = [];
    final pool = List<String>.from(dsLetterTitlePool)..shuffle(_rng);
    _letterTitles = ['পোশাক', 'মাথায় হেলমেট', 'হাতে গ্লাভস', 'হারনেস', ...pool];
    if (dsAllLevelsOpen) unlocked = dsLevels.length - 1;
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
  bool get shutdownLive => stamps.contains('cut') && !stamps.contains('restore');
  int get clockHour {
    final t = pack.startHour * 3600 + pack.startMinute * 60 + jobSeconds;
    return (t ~/ 3600) % 24;
  }

  int get clockMinute => ((pack.startHour * 3600 + pack.startMinute * 60 + jobSeconds) % 3600) ~/ 60;
  int get clockSecond => (pack.startHour * 3600 + pack.startMinute * 60 + jobSeconds) % 60;

  String get clockLabel {
    final h = clockHour.toString().padLeft(2, '0');
    final m = clockMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get clockFull {
    final s = clockSecond.toString().padLeft(2, '0');
    return '$clockLabel:$s';
  }

  DsLane get lane {
    if (act == DsAct.briefing) return DsLane.office;
    return step?.lane ?? DsLane.close;
  }

  DsLevelSpec get level => dsLevels[levelIndex.clamp(0, dsLevels.length - 1)];
  DsBrief briefOf([DsLevelSpec? spec]) {
    final s = spec ?? level;
    String? letterTitle;
    if (s.isLetters) {
      final i = s.number - 1;
      if (i >= 0 && i < _letterTitles.length) letterTitle = _letterTitles[i];
    }
    return dsBriefFor(s, letterTitle: letterTitle);
  }

  bool get lettersOnly => level.isLetters && level.number <= 2;
  List<DsPlanItem> get currentDeck => level.isLetters ? dsSafeHome : tonightPlan;
  int get choiceCount {
    final n = level.choices;
    return n <= 0 ? currentDeck.length : min(n, currentDeck.length);
  }

  bool get planning => act == DsAct.briefing && briefingPage == 0;
  bool get covering => planning && planPhase == DsPlanPhase.cover;
  bool get onRoad => planning && planPhase == DsPlanPhase.road;
  bool get listing => planning && planPhase == DsPlanPhase.list;
  var safeWalkDone = false;
  var dressArmed = false;
  var dressOpen = false;
  bool get showingSafeWalk => false;
  bool get dressLevel => level.isLetters && level.number <= 5;
  bool get showingDressIntro => listing && dressLevel && !dressOpen;
  bool get showingDress => listing && dressLevel && dressOpen;
  void finishSafeWalk() => safeWalkDone = true;

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
  bool get showHud => playing || showingDress || !planning;

  String get siteStory => fill(site.storyBn.isNotEmpty ? site.storyBn : site.introBn);

  var clockLive = false;
  var playSeconds = 0;
  var _playAcc = 0;

  int get hudLevelScore => (playing || showingDress || showingResult) ? levelScore : quality;
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

  String get levelRankBn => switch (levelRank) {
        DsLevelRank.darun => 'দারুণ',
        DsLevelRank.motamuti => 'মোটামুটি',
        DsLevelRank.again => 'আবার',
      };

  String get levelLineBn {
    if (level.isLetters && level.number == 1) {
      return switch (levelRank) {
        DsLevelRank.darun => 'পোশাক ঠিক আছে।',
        DsLevelRank.motamuti => 'পোশাক পরেছেন। ভুলগুলো মনে রাখুন।',
        DsLevelRank.again => 'পোশাক এখনো আলগা। আবার পরান।',
      };
    }
    if (level.isLetters && level.number == 2) {
      return switch (levelRank) {
        DsLevelRank.darun => 'হেলমেট ঠিক আছে।',
        DsLevelRank.motamuti => 'হেলমেট পরেছেন। ভুলগুলো মনে রাখুন।',
        DsLevelRank.again => 'মাথা এখনো খোলা। আবার পরান।',
      };
    }
    if (level.isLetters && level.number == 3) {
      return switch (levelRank) {
        DsLevelRank.darun => 'গ্লাভস ঠিক আছে।',
        DsLevelRank.motamuti => 'গ্লাভস পরেছেন। ভুলগুলো মনে রাখুন।',
        DsLevelRank.again => 'হাত এখনো খোলা। আবার পরান।',
      };
    }
    if (level.isLetters && level.number == 4) {
      return switch (levelRank) {
        DsLevelRank.darun => 'দুই আঙুল ঢোকে। হারনেস ঠিক আছে।',
        DsLevelRank.motamuti => 'হারনেস বেঁধেছেন। আঙুলের মাপ মনে রাখুন।',
        DsLevelRank.again => 'ফিতা এখনো ঢিলা। আবার বাঁধুন।',
      };
    }
    if (level.isLetters && level.number == 5) {
      return switch (levelRank) {
        DsLevelRank.darun => 'কিট ঠিক আছে।',
        DsLevelRank.motamuti => 'কিট পরেছেন। ভুলগুলো মনে রাখুন।',
        DsLevelRank.again => 'কিট এখনো আলগা। আবার পরান।',
      };
    }
    return switch (levelRank) {
      DsLevelRank.darun => 'ধাপগুলো মাথায় আছে।',
      DsLevelRank.motamuti => nearMiss ? 'আর একটা ঠিক থাকলে দারুণ।' : 'মোটামুটি মনে আছে। সাইটে ভুল করবেন না।',
      DsLevelRank.again => 'ধাপগুলো এখনো আলগা।',
    };
  }

  bool get nearMiss {
    if (levelRank != DsLevelRank.motamuti) return false;
    final deck = currentDeck.length;
    final darunWrong = deck <= 8 ? 1 : 3;
    if (wrongTaps == darunWrong + 1) return true;
    if (wrongTaps <= darunWrong && playSeconds > level.darunSec) return true;
    return false;
  }

  void addJobSeconds(int sec) {
    if (act == DsAct.done || act == DsAct.lethal || prePlay || playing) return;
    jobSeconds += sec;
    if (jobSeconds >= 2 * 3600 + 20 * 60) overtime = true;
  }

  void tickPlay(int millis) {
    if (!clockLive || showingResult || act == DsAct.done || act == DsAct.lethal) return;
    if (!(playing || showingDress || !planning)) return;
    _playAcc += millis;
    while (_playAcc >= 1000) {
      _playAcc -= 1000;
      playSeconds++;
    }
  }

  String get playClock {
    final m = (playSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (playSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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

  String fill(String raw) => raw
      .replaceAll('{{feeder}}', feeder)
      .replaceAll('{{fake1}}', fakes.isNotEmpty ? fakes[0] : 'রামপুর কলোনি-১১')
      .replaceAll('{{fake2}}', fakes.length > 1 ? fakes[1] : 'হাটতলা-১১')
      .replaceAll('{{pole}}', site.pole)
      .replaceAll('{{site}}', site.nameBn);

  String optionLabel(DsOption o) {
    final baked = fill(o.labelBn);
    if (baked.isNotEmpty) return baked;
    return switch (o.id) {
      'true' => feeder,
      'fake1' => fakes.isNotEmpty ? fakes[0] : 'রামপুর কলোনি-১১',
      'fake2' => fakes.length > 1 ? fakes[1] : 'হাটতলা-১১',
      'fake3' => fakes.length > 2 ? fakes[2] : 'পুরাতন রামপুর-১১',
      _ => o.labelBn,
    };
  }

  void openRoad() {
    if (planPhase != DsPlanPhase.cover && planPhase != DsPlanPhase.list && planPhase != DsPlanPhase.result) return;
    clockLive = false;
    planPhase = DsPlanPhase.road;
  }

  void openLevel(int index) {
    if (!onRoad) return;
    if (index < 0 || index >= dsLevels.length) return;
    if (!dsAllLevelsOpen && index > unlocked) return;
    levelIndex = index;
    dressArmed = false;
    dressOpen = false;
    planPhase = DsPlanPhase.list;
  }

  void backToRoad() {
    if (planPhase != DsPlanPhase.list && planPhase != DsPlanPhase.result) return;
    clockLive = false;
    dressArmed = false;
    dressOpen = false;
    planPhase = DsPlanPhase.road;
  }

  void startLevelPlay() {
    if (planPhase != DsPlanPhase.list) return;
    if (level.isField) {
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

  void retryPlay() {
    if (planPhase != DsPlanPhase.result) return;
    planPhase = DsPlanPhase.list;
    clockLive = false;
    dressArmed = false;
    dressOpen = false;
    planNext = 0;
    levelScore = 0;
    wrongTaps = 0;
    streak = 0;
    easyChoices = [];
  }

  void replayNow() {
    if (planPhase != DsPlanPhase.result) return;
    dressArmed = false;
    dressOpen = false;
    levelScore = 0;
    wrongTaps = 0;
    streak = 0;
    planPhase = DsPlanPhase.list;
    if (level.isLetters && level.number <= 5) {
      clockLive = false;
      return;
    }
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
    if (levelRank == DsLevelRank.again) return;
    nightTotal += levelScore;
    quality = nightTotal;
    final prev = bestRank[levelIndex];
    if (prev == null || _rankWeight(levelRank) > _rankWeight(prev)) {
      bestRank[levelIndex] = levelRank;
    }
    final old = bestDarunSec[levelIndex];
    if (old == null || playSeconds < old) bestDarunSec[levelIndex] = playSeconds;
    if (levelIndex + 1 > unlocked) unlocked = min(levelIndex + 1, dsLevels.length - 1);
  }

  int _rankWeight(DsLevelRank r) => switch (r) {
        DsLevelRank.darun => 2,
        DsLevelRank.motamuti => 1,
        DsLevelRank.again => 0,
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
    return DsResult(ok: false, lethal: true, noteBn: reason, delta: -5);
  }

  void _advance() {
    stepIndex++;
    _cardsSinceCall++;
    if (stepIndex >= pack.steps.length) {
      act = DsAct.done;
      return;
    }
    if (_maybeCall()) return;
    act = DsAct.card;
  }

  bool _maybeCall() {
    if (siteCalls.isEmpty || _callsFired >= 3) return false;
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
      act = stepIndex >= pack.steps.length ? DsAct.done : DsAct.card;
      return const DsResult(ok: true, delta: 5);
    }
    callsBad++;
    addScore(-5);
    safety = max(0, safety - 5);
    jumpMinutes(10);
    hardMiss = true;
    act = stepIndex >= pack.steps.length ? DsAct.done : DsAct.card;
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
