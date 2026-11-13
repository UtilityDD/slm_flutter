import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/en_digits.dart';
import '../duty_slip/duty_slip_voice.dart';
import '../game/learn_voice.dart';
import 'guide_director.dart';

/// Shared lip-sync notifier so [AiLinemanGuide] and legacy [DsCoach] adapters
/// animate mouth movement whenever the mascot speaks (via neural MP3 or TTS).
class MascotTalk {
  MascotTalk._();

  static final active = ValueNotifier<bool>(false);
  static var _depth = 0;
  static Timer? _safetyTimer;

  static void begin({Duration maxHold = const Duration(seconds: 12)}) {
    _depth++;
    if (!active.value) active.value = true;
    _safetyTimer?.cancel();
    _safetyTimer = Timer(maxHold, reset);
  }

  static void end() {
    if (_depth > 0) _depth--;
    if (_depth == 0) {
      _safetyTimer?.cancel();
      if (active.value) active.value = false;
    }
  }

  static void reset() {
    _depth = 0;
    _safetyTimer?.cancel();
    if (active.value) active.value = false;
  }
}

/// Lip-sync for the careless coworker / Learn rival only.
/// Never drives [AiLinemanGuide] — rival lines used to flip [MascotTalk] and
/// the guide kept mouth/body motion with an empty bubble.
class RivalTalk {
  RivalTalk._();

  static final active = ValueNotifier<bool>(false);
  static var _depth = 0;
  static Timer? _safetyTimer;

  static void begin({Duration maxHold = const Duration(seconds: 12)}) {
    _depth++;
    if (!active.value) active.value = true;
    _safetyTimer?.cancel();
    _safetyTimer = Timer(maxHold, reset);
  }

  static void end() {
    if (_depth > 0) _depth--;
    if (_depth == 0) {
      _safetyTimer?.cancel();
      if (active.value) active.value = false;
    }
  }

  static void reset() {
    _depth = 0;
    _safetyTimer?.cancel();
    if (active.value) active.value = false;
  }
}

/// High-level activity / event categories for the unified Game Mascot.
enum MascotCueId {
  // 1. Ladder Presence & Nudges
  ladderWelcomeNew,
  ladderWelcomeDaily,
  ladderWelcomeReturn,
  ladderIdleLevel,
  ladderIdleGift,
  ladderPoke,
  ladderComingSoon,
  ladderEmeraldGoal,
  ladderRankUp,
  ladderDeathRespawn,

  // 2. Touchable Side Items (_Station Props)
  sideHelmet,
  sideGloves,
  sideHarness,
  sideBoots,
  sideVest,
  sideLock,
  sideRope,
  sideCone,
  sideGoggles,
  sideGiftOpen,
  sideGiftRight,
  sideGiftWrong,
  sideIdentifyPrompt,
  sideIdentifyRight,
  sideIdentifyWrong,
  sideHourlyPrompt,
  sideHourlyRight,
  sideHourlyWrong,
  sideLifeSkill,
  sidePocketRule,

  // 3. Learn Card & Exit Quiz Coaching
  learnDeckStart,
  learnCardCheckOk,
  learnCardSpecOk,
  learnQuizStart,
  learnQuizRight,
  learnQuizWrongFirst,
  learnQuizWrongHint,
  learnDeckClear,

  // 4. Do Field Drill Universal Cues
  doPraiseRight,
  doMissFirst,
  doMissThink,
  doLevelClear,
}

/// A single structured speech & expression cue for the Game Mascot.
@immutable
class MascotCue {
  final String id;
  final String textBn;
  final GuideMood mood;
  final GuideGesture gesture;

  /// Optional key into [DsVoice] pre-synthesized neural audio map.
  final String? voiceKey;

  const MascotCue({
    required this.id,
    required this.textBn,
    this.mood = GuideMood.talk,
    this.gesture = GuideGesture.none,
    this.voiceKey,
  });

  String get displayBn => enDigits(textBn);
}

/// Centralized natural field-Bangla speech library & voice player for the
/// unified Game Mascot ("ওস্তাদ লাইনম্যান").
class MascotSpeechLibrary {
  MascotSpeechLibrary._();

  static final _rng = math.Random();
  static int _cycle = 0;
  static FlutterTts? _tts;
  static bool _ttsReady = false;
  static int _speakToken = 0;

  /// The silent reading hold of a rival line with no recorded clip (see
  /// [speak]); a new line or [stop] ends it at once.
  static Completer<void>? _silentHold;
  static Timer? _silentTimer;

  static void _endSilentHold() {
    _silentTimer?.cancel();
    _silentTimer = null;
    final h = _silentHold;
    _silentHold = null;
    if (h != null && !h.isCompleted) h.complete();
  }

  /// Widget tests skip the silent reading hold of an unrecorded rival line
  /// (the device voice returned at once there too); a test that checks the
  /// hold sets this and resets it in tearDown.
  static bool debugSilentHoldInTests = false;
  static final bool _inWidgetTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// A fair reading time for a caption of [textBn] (used when a line is not
  /// voiced: muted, or a rival line with no recorded clip yet).
  static Duration readHold(String textBn) {
    final chars = textBn.trim().length;
    return Duration(milliseconds: (900 + chars * 55).clamp(1800, 5200));
  }

  // ===========================================================================
  // 1. LADDER PRESENCE, WELCOME, IDLE NUDGE & POKE LINES
  // ===========================================================================

  static const _welcomeNewPool = <MascotCue>[
    MascotCue(
      id: 'ladder.welcome.new.1',
      textBn: 'হ্যালো! আমি ওস্তাদ, আপনার সেফটি গাইড। চলুন, প্রথম ধাপ থেকে শুরু করি!',
      mood: GuideMood.wake,
    ),
    MascotCue(
      id: 'ladder.welcome.new.2',
      textBn: 'হাই! স্বাগতম। খেলতে খেলতে নিরাপদে কাজ শিখব—প্রথম ধাপে ট্যাপ করুন।',
      mood: GuideMood.wake,
    ),
  ];

  static const _welcomeDailyPool = <MascotCue>[
    MascotCue(
      id: 'ladder.welcome.daily.1',
      textBn: 'হ্যালো! আবার দেখা হলো। আজকের ডিউটি শুরু করি?',
      mood: GuideMood.wake,
    ),
    MascotCue(
      id: 'ladder.welcome.daily.2',
      textBn: 'ওয়েলকাম ব্যাক! চলুন, পরের ধাপটা সেরে ফেলি।',
      mood: GuideMood.wake,
    ),
    MascotCue(
      id: 'ladder.welcome.daily.3',
      textBn: 'হাই! আজও এসেছেন—দারুণ! চলুন এগোই।',
      mood: GuideMood.wake,
    ),
  ];

  static const _welcomeReturnPool = <MascotCue>[
    MascotCue(
      id: 'ladder.welcome.return.1',
      textBn: 'হাই! আবার এলেন? চলুন, যেখানে ছিলাম।',
      mood: GuideMood.talk,
    ),
    MascotCue(
      id: 'ladder.welcome.return.2',
      textBn: 'ওয়েলকাম ব্যাক! পরের ধাপটা আপনার অপেক্ষায়।',
      mood: GuideMood.talk,
    ),
    MascotCue(
      id: 'ladder.welcome.return.3',
      textBn: 'হ্যালো! চলুন, আরেকটা ধাপ উঠি।',
      mood: GuideMood.talk,
    ),
  ];

  static const _idleLevelPool = <MascotCue>[
    MascotCue(
      id: 'ladder.idle.level.1',
      textBn: 'সামনের ধাপটা জ্বলছে—ট্যাপ করুন, কাজটা সেরে নিই!',
      mood: GuideMood.inspire,
    ),
    MascotCue(
      id: 'ladder.idle.level.2',
      textBn: 'দাঁড়িয়ে ভাবছেন কী? এই ধাপে ট্যাপ করুন, মাঠে নেমে পড়ি।',
      mood: GuideMood.talk,
    ),
    MascotCue(
      id: 'ladder.idle.level.3',
      textBn: 'এক ট্যাপেই শুরু—নিয়ম মানলে পয়েন্ট আপনার হাতেই!',
      mood: GuideMood.inspire,
    ),
    MascotCue(
      id: 'ladder.idle.level.4',
      textBn: 'প্রস্তুত তো? জ্বলন্ত ধাপটায় চাপ দিন, ওপরে ওঠা যাক।',
      mood: GuideMood.talk,
    ),
  ];

  static const _idleGiftPool = <MascotCue>[
    MascotCue(
      id: 'ladder.idle.gift.1',
      textBn: 'পাশে একটা টুলবক্স অপেক্ষা করছে! ট্যাপ করে খুলে দেখুন।',
      mood: GuideMood.glad,
    ),
    MascotCue(
      id: 'ladder.idle.gift.2',
      textBn: 'ওই দেখুন হঠাৎ উপহার—টুলবক্সটা খুলতে একবার ট্যাপ করুন!',
      mood: GuideMood.inspire,
    ),
    MascotCue(
      id: 'ladder.idle.gift.3',
      textBn: 'টুলবক্সটা এখনো বন্ধ—ভেতরে কী আছে, একবার দেখে নিন!',
      mood: GuideMood.talk,
    ),
  ];

  static const _pokePool = <MascotCue>[
    MascotCue(
      id: 'ladder.poke.1',
      textBn: 'মনে রাখবেন—হেলমেটের চিন-স্ট্র্যাপ শক্ত করে না বাঁধলে পড়ে যাওয়ার সময় কোনো কাজ হবে না!',
      mood: GuideMood.talk,
      gesture: GuideGesture.leanRight,
    ),
    MascotCue(
      id: 'ladder.poke.2',
      textBn: 'তারে হাত দেওয়ার আগে গ্লাভস গুটিয়ে ফুঁ দিয়ে দেখুন—একটুও এয়ার লিক থাকলে ওই গ্লাভস বাতিল!',
      mood: GuideMood.inspire,
      gesture: GuideGesture.leanLeft,
    ),
    MascotCue(
      id: 'ladder.poke.3',
      textBn: 'শাটডাউন নিলেও লাইন টেস্টার দিয়ে আগে চেক করুন, তারপর দুপাশে আর্থিং রড লাগান!',
      mood: GuideMood.warn,
      gesture: GuideGesture.peek,
    ),
    MascotCue(
      id: 'ladder.poke.4',
      textBn: 'পোলে ওঠার সময় দুটো ল্যানিয়ার্ডের নিয়ম মানুন—লাইন পার করার সময়ও এক মুহূর্তের জন্য বেল্ট খুলবেন না!',
      mood: GuideMood.inspire,
      gesture: GuideGesture.spinHop,
    ),
    MascotCue(
      id: 'ladder.poke.5',
      textBn: 'পোলে ওঠার আগে হাতুড়ি বা লাঠি ঠুকে শুনুন—নিরেট ঠক্-ঠক্ না হয়ে ভোঁতা দপ্-দপ্ শব্দ হলে ওই পোল বিপজ্জনক!',
      mood: GuideMood.warn,
      gesture: GuideGesture.leanRight,
    ),
    MascotCue(
      id: 'ladder.poke.6',
      textBn: 'কখনো হাত দিয়ে টুলস ওপরে ছুঁড়ে দেবেন না—সবসময় শুকনো ক্যানভাস ব্যাগ আর হ্যান্ড-লাইন দড়ি ব্যবহার করুন!',
      mood: GuideMood.talk,
      gesture: GuideGesture.leanLeft,
    ),
    MascotCue(
      id: 'ladder.poke.7',
      textBn: 'স্টে-ওয়ারে কখনো লিকেজ কারেন্ট থাকতে পারে—কাজ করার আগে স্টে-ওয়ারেও টেস্টার ছুঁইয়ে দেখুন!',
      mood: GuideMood.warn,
      gesture: GuideGesture.peek,
    ),
    MascotCue(
      id: 'ladder.poke.8',
      textBn: 'তাড়াহুড়ো একদম নয় ভাই—প্রতিদিন ০ মৃত্যুঝুঁকি নিয়ে ঘরে ফেরার শপথ আমাদের!',
      mood: GuideMood.glad,
      gesture: GuideGesture.spinHop,
    ),
  ];

  static const _funnyIdlePool = <MascotCue>[
    MascotCue(
      id: 'ladder.gag.1',
      textBn: 'একটু হাত-পা ছাড়িয়ে নিলাম—এবার চলুন কাজে নামা যাক!',
      mood: GuideMood.glad,
      gesture: GuideGesture.spinHop,
    ),
    MascotCue(
      id: 'ladder.gag.2',
      textBn: 'ওপরের লাইনটা এখান থেকেই নজরে রাখছি!',
      mood: GuideMood.talk,
      gesture: GuideGesture.peek,
    ),
    MascotCue(
      id: 'ladder.gag.3',
      textBn: 'কী খবর ভাই? পরের ধাপে হাত লাগাব নাকি?',
      mood: GuideMood.inspire,
      gesture: GuideGesture.leanRight,
    ),
  ];

  // ===========================================================================
  // 2. TOUCHABLE SIDE ITEMS (_Station PROPS ON LADDER)
  // ===========================================================================

  static const _sidePropCues = <String, MascotCue>{
    'helmet': MascotCue(
      id: 'side.helmet',
      textBn: 'মাথায় গামছা থাকলে Helmet ঠিকমতো বসবে না! চিন-স্ট্র্যাপ লক করে Class-E হেলমেট পরুন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_why_gamcha_block',
    ),
    'gloves': MascotCue(
      id: 'side.gloves',
      textBn: 'কাজের আগে Gloves মুড়িয়ে হাওয়া ভরে দেখুন—সূক্ষ্ম পিন-হোল থাকলেও 11 kV শক লাগবে!',
      mood: GuideMood.inspire,
      voiceKey: 'ds_why_hole',
    ),
    'harness': MascotCue(
      id: 'side.harness',
      textBn: 'কোমরের বেল্ট নয়, Full-Body Harness পরুন—পিঠের D-ring কাঁধের মাঝখানে আর দুই আঙুলের ছাড় রাখুন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_why_belt',
    ),
    'boots': MascotCue(
      id: 'side.boots',
      textBn: 'চপ্পল বা সাধারণ জুতোয় ইনসুলেশন থাকে না—পোলে ও সাবস্টেশনে Dielectric Safety Boot বাধ্যতামূলক।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_why_slip',
    ),
    'vest': MascotCue(
      id: 'side.vest',
      textBn: 'পলিয়েস্টার কাপড় আর্ক ফ্ল্যাশে গলে চামড়ায় আটকে যায়! ফুল-হাতা সুতির পোশাক ও রিফ্লেক্টিভ জ্যাকেট পরুন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_why_poly',
    ),
    'lock': MascotCue(
      id: 'side.lock',
      textBn: 'মৌখিক কথায় ভরসা নয়—ব্রেকার অফ করে নিজের হাতে LOTO তালা ও Danger Tag লাগিয়ে PTW নিন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_l8_start',
    ),
    'rope': MascotCue(
      id: 'side.rope',
      textBn: 'পোলে টুলস বা তার তোলার সময় হাতে না বয়ে শুকনো Hand-Rope ও টুল-ব্যাগ ব্যবহার করুন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_l7_start',
    ),
    'cone': MascotCue(
      id: 'side.cone',
      textBn: 'রাস্তার ধারে কাজ শুরুর আগে Traffic Cone ও ফিতে দিয়ে ভিড় সরিয়ে লক্ষ্মণ রেখা তৈরি করুন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_l14_crowd_first',
    ),
    'goggles': MascotCue(
      id: 'side.goggles',
      textBn: 'ফিউজ বাঁধা বা প্যানেল সুইচিংয়ের সময় আর্কের ফুলকি থেকে চোখ বাঁচাতে Safety Goggles / Face Shield পরুন।',
      mood: GuideMood.inspire,
      voiceKey: 'ds_l6_room_no_shield',
    ),
  };

  // ===========================================================================
  // 3. LEARN CARD & QUICK-FIRE QUIZ COACHING
  // ===========================================================================

  static const _learnCheckOkPool = <MascotCue>[
    MascotCue(
      id: 'learn.check.1',
      textBn: 'সাবাশ! কাজের আগে এই ছোট্ট চেকটাই মাঠে আপনার প্রাণ বাঁচাবে।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_1',
    ),
    MascotCue(
      id: 'learn.check.2',
      textBn: 'একদম নিখুঁত নজর! সরঞ্জাম যাচাই করে তবেই কাজে হাত দেবেন।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_2',
    ),
    MascotCue(
      id: 'learn.check.3',
      textBn: 'ঠিক ধরেছেন! এই অভ্যাসটাই একজন পাকা লাইনম্যানের পরিচয়।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_4',
    ),
  ];

  static const _learnQuizRightPool = <MascotCue>[
    MascotCue(
      id: 'learn.quiz.right.1',
      textBn: 'দারুণ! মাঠের নিয়ম আপনার একদম নখদর্পণে আছে।',
      mood: GuideMood.celebrate,
      gesture: GuideGesture.spinHop,
      voiceKey: 'ds_exp_right_2',
    ),
    MascotCue(
      id: 'learn.quiz.right.2',
      textBn: 'সঠিক সিদ্ধান্ত! এভাবেই ঠান্ডা মাথায় কাজ করতে হবে।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_3',
    ),
  ];

  static const _learnQuizWrongPool = <MascotCue>[
    MascotCue(
      id: 'learn.quiz.wrong.1',
      textBn: 'আরে, একটু ভুল হলো! তাড়াহুড়ো না করে নিয়মটা আরেকবার ভাবুন।',
      mood: GuideMood.warn,
      voiceKey: 'ds_wrong_bhabun',
    ),
    MascotCue(
      id: 'learn.quiz.wrong.2',
      textBn: 'না ভাই, ওটা ঝুঁকির পথ! নিচের ইঙ্গিতটা দেখে সঠিকটা বেছে নিন।',
      mood: GuideMood.warn,
      voiceKey: 'ds_wrong_niyom',
    ),
  ];

  // ===========================================================================
  // 4. DO FIELD DRILL PRAISE & FAULT COACHING
  // ===========================================================================

  static const _doRightPool = <MascotCue>[
    MascotCue(
      id: 'do.right.1',
      textBn: 'সাবাশ! একদম ঠিক।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_1',
    ),
    MascotCue(
      id: 'do.right.2',
      textBn: 'বাঃ, একদম নিখুঁত নির্বাচন!',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_2',
    ),
    MascotCue(
      id: 'do.right.3',
      textBn: 'সঠিক সিদ্ধান্ত, পরের ধাপে চলুন।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_3',
    ),
    MascotCue(
      id: 'do.right.4',
      textBn: 'চমৎকার! যথাযথ ফিটিং হয়েছে।',
      mood: GuideMood.glad,
      voiceKey: 'ds_exp_right_4',
    ),
  ];

  static const _doMissFirstPool = <MascotCue>[
    MascotCue(
      id: 'do.miss.1',
      textBn: 'না, হলো না—আবার ভেবে দেখুন।',
      mood: GuideMood.warn,
      voiceKey: 'ds_wrong_bhabun',
    ),
    MascotCue(
      id: 'do.miss.2',
      textBn: 'ভুল হলো! নিয়মটি আবার মনে করুন।',
      mood: GuideMood.warn,
      voiceKey: 'ds_wrong_niyom',
    ),
  ];

  // ===========================================================================
  // PUBLIC LOOKUP API
  // ===========================================================================

  /// Returns a [MascotCue] for the given high-level [MascotCueId].
  static MascotCue cueFor(MascotCueId id) {
    final idx = _cycle++;
    return switch (id) {
      MascotCueId.ladderWelcomeNew => _welcomeNewPool[idx % _welcomeNewPool.length],
      MascotCueId.ladderWelcomeDaily => _welcomeDailyPool[idx % _welcomeDailyPool.length],
      MascotCueId.ladderWelcomeReturn => _welcomeReturnPool[idx % _welcomeReturnPool.length],
      MascotCueId.ladderIdleLevel => _idleLevelPool[idx % _idleLevelPool.length],
      MascotCueId.ladderIdleGift => _idleGiftPool[idx % _idleGiftPool.length],
      MascotCueId.ladderPoke => _pokePool[idx % _pokePool.length],
      MascotCueId.ladderComingSoon => const MascotCue(
          id: 'ladder.soon',
          textBn: 'এই ধাপটা তৈরি হচ্ছে ভাই—তার আগে নিচের ধাপগুলো পাকা করে নিন!',
          mood: GuideMood.talk,
        ),
      MascotCueId.ladderEmeraldGoal => const MascotCue(
          id: 'ladder.emerald',
          textBn: 'মৃত্যুহীন পথের শীর্ষ চূড়া! প্রতিটি ধাপে বাঁচার অভ্যাসই আমাদের আসল জয়।',
          mood: GuideMood.celebrate,
          gesture: GuideGesture.spinHop,
        ),
      MascotCueId.ladderRankUp => const MascotCue(
          id: 'ladder.rank_up',
          textBn: 'অভিনন্দন ওস্তাদ! নতুন র‍্যাঙ্ক শিল্ড অর্জন করেছেন—এগিয়ে চলুন!',
          mood: GuideMood.celebrate,
          gesture: GuideGesture.spinHop,
          voiceKey: 'ds_exp_right_2',
        ),
      MascotCueId.ladderDeathRespawn => const MascotCue(
          id: 'ladder.respawn',
          textBn: 'মন খারাপ করবেন না ভাই, চেকপয়েন্ট থেকে আবার শুরু করুন—এবার সবকটা চেক সেরে উঠব।',
          mood: GuideMood.inspire,
          voiceKey: 'ds_wrong_niyom',
        ),
      MascotCueId.sideHelmet => _sidePropCues['helmet']!,
      MascotCueId.sideGloves => _sidePropCues['gloves']!,
      MascotCueId.sideHarness => _sidePropCues['harness']!,
      MascotCueId.sideBoots => _sidePropCues['boots']!,
      MascotCueId.sideVest => _sidePropCues['vest']!,
      MascotCueId.sideLock => _sidePropCues['lock']!,
      MascotCueId.sideRope => _sidePropCues['rope']!,
      MascotCueId.sideCone => _sidePropCues['cone']!,
      MascotCueId.sideGoggles => _sidePropCues['goggles']!,
      MascotCueId.sideGiftOpen => const MascotCue(
          id: 'side.gift.open',
          textBn: 'সারপ্রাইজ বক্স! এই ছোট্ট ফিল্ড চ্যালেঞ্জটা মিলিয়ে বোনাস পয়েন্ট জিতে নিন!',
          mood: GuideMood.glad,
          gesture: GuideGesture.peek,
        ),
      MascotCueId.sideGiftRight => const MascotCue(
          id: 'side.gift.right',
          textBn: 'সাবাশ! একদম সঠিক উত্তর—বোনাস পয়েন্ট আপনার ঝুলিতে!',
          mood: GuideMood.celebrate,
          gesture: GuideGesture.spinHop,
          voiceKey: 'ds_exp_right_1',
        ),
      MascotCueId.sideGiftWrong => const MascotCue(
          id: 'side.gift.wrong',
          textBn: 'ওহো, একটু ফসকে গেল! সঠিক নিয়মটা দেখে নিন।',
          mood: GuideMood.warn,
          voiceKey: 'ds_wrong_bhabun',
        ),
      MascotCueId.sideIdentifyPrompt => const MascotCue(
          id: 'side.identify.prompt',
          textBn: 'পাকা লাইনম্যানের নজর পরীক্ষা! বলুন তো কোনটা সঠিক নিয়ম?',
          mood: GuideMood.talk,
        ),
      MascotCueId.sideIdentifyRight => _learnQuizRightPool[0],
      MascotCueId.sideIdentifyWrong => _learnQuizWrongPool[0],
      MascotCueId.sideHourlyPrompt => const MascotCue(
          id: 'side.hourly.prompt',
          textBn: 'কুইক ফিল্ড কল! ৫ সেকেন্ডে ভাবুন—মাঠে এখন কী করবেন?',
          mood: GuideMood.inspire,
        ),
      MascotCueId.sideHourlyRight => _learnQuizRightPool[1],
      MascotCueId.sideHourlyWrong => _learnQuizWrongPool[1],
      MascotCueId.sideLifeSkill => const MascotCue(
          id: 'side.life',
          textBn: 'মনে রাখবেন—অন্ধকারে বা ঝড়-বৃষ্টিতে তাড়াহুড়ো করে পোলে ওঠা মানেই বিপদ ডেকে আনা।',
          mood: GuideMood.inspire,
        ),
      MascotCueId.sidePocketRule => const MascotCue(
          id: 'side.rule',
          textBn: 'সোনার নিয়ম: লিখিত PTW, ভোল্টেজ টেস্ট, ডিসচার্জ রড আর দুদিক আর্থিং ছাড়া লাইন ছোঁয়া মানা!',
          mood: GuideMood.inspire,
          voiceKey: 'ds_l6_done',
        ),
      MascotCueId.learnDeckStart => const MascotCue(
          id: 'learn.start',
          textBn: 'চলুন, কাজের আগে জরুরি পয়েন্টগুলো ছুঁয়ে যাচাই করে নিই!',
          mood: GuideMood.talk,
        ),
      MascotCueId.learnCardCheckOk => _learnCheckOkPool[idx % _learnCheckOkPool.length],
      MascotCueId.learnCardSpecOk => const MascotCue(
          id: 'learn.spec',
          textBn: 'ভোল্টেজ রেটিং আর টেস্টের নিয়মটা মাথায় রাখবেন—এটাই আসল সুরক্ষা।',
          mood: GuideMood.inspire,
          voiceKey: 'ds_exp_right_3',
        ),
      MascotCueId.learnQuizStart => const MascotCue(
          id: 'learn.quiz.start',
          textBn: 'চেক সম্পূর্ণ! এবার ২টি কুইক ফিল্ড সিদ্ধান্তের উত্তর দিন।',
          mood: GuideMood.inspire,
        ),
      MascotCueId.learnQuizRight => _learnQuizRightPool[idx % _learnQuizRightPool.length],
      MascotCueId.learnQuizWrongFirst => _learnQuizWrongPool[0],
      MascotCueId.learnQuizWrongHint => _learnQuizWrongPool[1],
      MascotCueId.learnDeckClear => const MascotCue(
          id: 'learn.clear',
          textBn: 'চমৎকার! পাঠ সম্পূর্ণ—এবার চলুন সরাসরি মাঠে হাত পাকাই!',
          mood: GuideMood.celebrate,
          gesture: GuideGesture.spinHop,
          voiceKey: 'ds_exp_right_1',
        ),
      MascotCueId.doPraiseRight => _doRightPool[idx % _doRightPool.length],
      MascotCueId.doMissFirst => _doMissFirstPool[idx % _doMissFirstPool.length],
      MascotCueId.doMissThink => _doMissFirstPool[0],
      MascotCueId.doLevelClear => const MascotCue(
          id: 'do.clear',
          textBn: 'সাবাশ ওস্তাদ! মাঠের কাজ নিখুঁতভাবে শেষ করেছেন—পরের ধাপে চলুন!',
          mood: GuideMood.celebrate,
          gesture: GuideGesture.spinHop,
          voiceKey: 'ds_exp_right_1',
        ),
    };
  }

  /// Random natural idle gag cue for long quiet moments on the ladder.
  static MascotCue randomFunnyIdle() => _funnyIdlePool[_rng.nextInt(_funnyIdlePool.length)];

  // ===========================================================================
  // 5. NATURAL FIELD BANGLA NORMALIZER (FOR LEARN CARDS & QUIZZES)
  // ===========================================================================

  /// Converts stiff textbook Bangla terms into natural West Bengal lineman field
  /// speech while keeping everyday English technical terms and Western digits `0–9`.
  static String toNaturalFieldBangla(String raw) {
    if (raw.trim().isEmpty) return '';
    var out = raw.trim();
    // Strip markdown bold/headers/bullets for clean card & voice display.
    out = out
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll('দস্তানা', 'গ্লাভস')
        .replaceAll('হস্তাবরণী', 'গ্লাভস')
        .replaceAll('শিরস্ত্রাণ', 'হেলমেট')
        .replaceAll('পাদুকা', 'সেফটি বুট')
        .replaceAll('নিরাপত্তা বেল্ট', 'সেফটি হারনেস')
        .replaceAll('বিচ্ছিন্নকরণ', 'শাটডাউন ও আইসোলেশন')
        .replaceAll('ভূ-সংযোগ', 'আর্থিং');
    return enDigits(out);
  }

  /// Extracts a concise, punchy 1-to-2 sentence field takeaway (never a textbook wall)
  /// from a longer lesson explanation.
  static String conciseFieldRule(String raw, {int maxChars = 135}) {
    final clean = toNaturalFieldBangla(raw).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxChars) return clean;
    // Try to cut cleanly at the first or second Bengali danda '।' or '!'
    final parts = clean.split(RegExp(r'(?<=[।!?])\s+'));
    if (parts.isNotEmpty && parts.first.length >= 24 && parts.first.length <= maxChars) {
      if (parts.length > 1 && (parts[0].length + 1 + parts[1].length) <= maxChars) {
        return '${parts[0]} ${parts[1]}';
      }
      return parts.first;
    }
    return '${clean.substring(0, maxChars - 1).trimRight()}…';
  }

  // ===========================================================================
  // 6. UNIFIED VOICE + LIP-SYNC ENGINE (NEURAL MP3 FIRST -> TTS FALLBACK)
  // ===========================================================================

  /// Speaks the given [cue] or raw [textBn]. Guide lines drive [MascotTalk];
  /// [rival] lines drive [RivalTalk] only so the app mascot stays still.
  static Future<void> speak(
    String textBn, {
    String? voiceKey,
    bool muted = false,
    double pitch = 1.0,
    double rate = 0.48,
    bool rival = false,
  }) async {
    final token = ++_speakToken;
    _endSilentHold();
    if (muted || textBn.trim().isEmpty) {
      MascotTalk.reset();
      RivalTalk.reset();
      return;
    }

    final cleanText = toNaturalFieldBangla(textBn);
    final hold = _estimateHold(cleanText);
    void beginLips() {
      if (rival) {
        MascotTalk.reset();
        RivalTalk.begin(maxHold: hold);
      } else {
        RivalTalk.reset();
        MascotTalk.begin(maxHold: hold);
      }
    }

    void endLips() {
      if (rival) {
        RivalTalk.end();
      } else {
        MascotTalk.end();
      }
    }

    void resetLips() {
      if (rival) {
        RivalTalk.reset();
      } else {
        MascotTalk.reset();
      }
    }

    bool lipsOpen() => rival ? RivalTalk.active.value : MascotTalk.active.value;

    // 1. Check if we have a pre-synthesized neural MP3 in DsVoice (by voiceKey or exact text)
    final resolvedKey = rival
        ? null
        : (voiceKey != null && DsVoice.hasAudio(voiceKey))
            ? voiceKey
            : (DsVoice.hasAudio(cleanText)
                ? cleanText
                : (DsVoice.hasAudio(textBn.trim()) ? textBn.trim() : null));

    // 1b. Learn voice pack: the coach's other fixed lines, and the rival's own voice.
    final learnClip = resolvedKey != null
        ? null
        : LearnVoice.resolve(textBn, rival: rival) ?? LearnVoice.resolve(cleanText, rival: rival);

    if (resolvedKey != null || learnClip != null) {
      await _stopTts();
      DsVoice.stop();
      LearnVoice.stop();
      beginLips();
      try {
        if (learnClip != null) {
          await LearnVoice.play(learnClip);
        } else {
          await DsVoice.play(resolvedKey!, muted: false);
        }
      } finally {
        if (token == _speakToken) {
          endLips();
        }
      }
      return;
    }

    // 1c. The rival speaks only in his recorded voice: a line with no clip yet
    // is never read by the device voice (that is the guide's voice, and his
    // mouth would move with it). He stays silent and his caption is held for
    // a reading time; a new line or [stop] ends the hold.
    if (rival) {
      DsVoice.stop();
      LearnVoice.stop();
      await _stopTts();
      MascotTalk.reset();
      RivalTalk.reset();
      if (token != _speakToken) return;
      if (_inWidgetTest && !debugSilentHoldInTests) return;
      final hold = _silentHold = Completer<void>();
      _silentTimer = Timer(readHold(cleanText), _endSilentHold);
      await hold.future;
      return;
    }

    // 2. Otherwise use FlutterTts (bn-IN). Lips open on the engine's start
    // callback (not before), so the mouth never runs ahead of the voice.
    DsVoice.stop();
    LearnVoice.stop();
    var began = false;
    void open() {
      if (began || token != _speakToken) return;
      began = true;
      beginLips();
    }

    Timer? startGuard;
    try {
      final tts = await _ensureTts();
      if (tts == null || token != _speakToken) {
        resetLips();
        return;
      }
      await tts.stop();
      await tts.setPitch(pitch);
      await tts.setSpeechRate(rate);
      if (token != _speakToken) return;
      tts.setStartHandler(open);
      tts.setCompletionHandler(() {
        if (token == _speakToken && began) endLips();
      });
      tts.setCancelHandler(() {
        if (token == _speakToken) resetLips();
      });
      tts.setErrorHandler((_) {
        if (token == _speakToken) resetLips();
      });
      // Engines that never report start still get lips after a short beat.
      startGuard = Timer(const Duration(milliseconds: 650), open);
      await tts.speak(cleanText);
    } catch (_) {
      if (token == _speakToken) resetLips();
    } finally {
      startGuard?.cancel();
      // awaitSpeakCompletion should finish with the utterance; clear lip-sync if still open.
      if (token == _speakToken && lipsOpen()) {
        resetLips();
      }
    }
  }

  /// Rough max hold so lip-sync never outlives a hung TTS session.
  static Duration _estimateHold(String text) {
    final chars = text.trim().length;
    final ms = (1200 + chars * 85).clamp(2500, 18000);
    return Duration(milliseconds: ms);
  }

  /// Wait until lip-sync / voice finishes (bubble + host should call this before clearing text).
  static Future<void> waitUntilQuiet({
    Duration timeout = const Duration(seconds: 18),
  }) async {
    if (!MascotTalk.active.value) return;
    final done = Completer<void>();
    void listener() {
      if (!MascotTalk.active.value && !done.isCompleted) done.complete();
    }

    MascotTalk.active.addListener(listener);
    try {
      await done.future.timeout(timeout, onTimeout: () {});
    } finally {
      MascotTalk.active.removeListener(listener);
    }
  }

  /// Stops any active mascot speech (both neural MP3 and TTS) and resets lip-sync immediately.
  static Future<void> stop() async {
    _speakToken++;
    _endSilentHold();
    MascotTalk.reset();
    RivalTalk.reset();
    DsVoice.stop();
    LearnVoice.stop();
    await _stopTts();
  }

  /// Starts the TTS engine (language, rate) without speaking, so the guide's
  /// first line does not wait for it (done while the brand intro plays).
  static Future<void> warmUp() async {
    await _ensureTts();
  }

  static Future<FlutterTts?> _ensureTts() async {
    try {
      if (_tts == null) {
        _tts = FlutterTts();
        await _tts!.setLanguage('bn-IN');
        await _tts!.setSpeechRate(0.48);
        await _tts!.setPitch(1.0);
        await _tts!.awaitSpeakCompletion(true);
        _ttsReady = true;
      } else if (!_ttsReady) {
        await _tts!.setLanguage('bn-IN');
        await _tts!.awaitSpeakCompletion(true);
        _ttsReady = true;
      }
      return _tts;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _stopTts() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

