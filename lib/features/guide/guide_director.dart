import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/en_digits.dart';
import '../game/content_catalog.dart';
import '../game/game_save.dart';
import 'mascot_speech_library.dart';

enum GuideMood {
  idle,
  listen,
  talk,
  think,
  glad,
  celebrate,
  warn,
  fright,
  fallen,
  inspire,
  sleep,
  wake,
}

/// Body gag layered on top of face mood (smoothly animated in the widget).
enum GuideGesture {
  none,
  handstand,
  leanLeft,
  leanRight,
  peek,
  spinHop,
}

enum GuideEntranceKind { dailyWelcome, hiPop, comeback }

/// Back on the ladder from a level in the same app session: no welcome again,
/// just a quick word about where the player stands.
abstract final class LadderComebackLines {
  static const climbed = <String>[
    'এক ধাপ উপরে! চলুন, পরেরটা।',
    'সাবাশ! পরের ধাপ আপনার অপেক্ষায়।',
    'দারুণ চলছে! থামবেন না।',
    'আরও একটা ধাপ পার! এগিয়ে চলুন।',
  ];
  /// A rung passed again (replay): praise without claiming a new rung.
  static const passedAgain = <String>[
    'সাবাশ! পরের ধাপ আপনার অপেক্ষায়।',
    'দারুণ চলছে! থামবেন না।',
  ];
  static const same = <String>[
    'আবার চেষ্টা করলেই হবে, আমি আছি।',
    'কোন ধাপে যাবেন? আমি সঙ্গে আছি।',
    'একটু ভেবে নিয়ে আবার শুরু করুন।',
  ];
}

@immutable
class GuideState {
  final GuideMood mood;
  final GuideGesture gesture;
  final String line;
  final int token;
  final GuideEntranceKind? entrance;
  final bool levelFocus;

  const GuideState({
    required this.mood,
    required this.gesture,
    required this.line,
    required this.token,
    this.entrance,
    this.levelFocus = false,
  });

  static const quiet = GuideState(
    mood: GuideMood.idle,
    gesture: GuideGesture.none,
    line: '',
    token: 0,
  );

  GuideState copyWith({
    GuideMood? mood,
    GuideGesture? gesture,
    String? line,
    int? token,
    GuideEntranceKind? entrance,
    bool clearEntrance = false,
    bool? levelFocus,
  }) =>
      GuideState(
        mood: mood ?? this.mood,
        gesture: gesture ?? this.gesture,
        line: line ?? this.line,
        token: token ?? this.token,
        entrance: clearEntrance ? null : (entrance ?? this.entrance),
        levelFocus: levelFocus ?? this.levelFocus,
      );
}

class GuideDirector extends Notifier<GuideState> {
  static const _welcomeDayKey = 'guide_last_welcome_day_v1';

  int _token = 0;
  DateTime _lastInspire = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastGag = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastPoke = DateTime.fromMillisecondsSinceEpoch(0);
  final _rng = math.Random();
  bool _entranceMuted = false;
  String? _entranceVoiceKey;
  GuideMood _entranceMood = GuideMood.talk;
  GuideGesture _entranceGesture = GuideGesture.none;

  /// Cleared rungs at the last ladder entrance of this app session (null = none yet).
  int? _clearedAtEntrance;

  /// [GameSave.safeStreak] at the last entrance: it grows on every pass,
  /// replays included, so a replayed pass is not mistaken for "try again".
  int? _streakAtEntrance;
  int _comebackPick = 0;

  bool get levelFocus => state.levelFocus;

  /// Pause ladder mascot idle while a level route owns the coach.
  void setLevelFocus(bool active) {
    if (active) {
      _lastInspire = DateTime.now();
      _lastGag = DateTime.now();
      state = GuideState(
        mood: GuideMood.idle,
        gesture: GuideGesture.none,
        line: '',
        token: ++_token,
        levelFocus: true,
      );
      return;
    }
    state = state.copyWith(levelFocus: false, token: ++_token);
  }

  @override
  GuideState build() => GuideState.quiet;

  void say({
    required GuideMood mood,
    required String line,
    GuideGesture gesture = GuideGesture.none,
    GuideEntranceKind? entrance,
    String? voiceKey,
    bool speakVoice = false,
    bool muted = false,
  }) {
    _token++;
    final cleanLine = enDigits(line);
    state = GuideState(
      mood: mood,
      gesture: gesture,
      line: cleanLine,
      token: _token,
      entrance: entrance,
      levelFocus: state.levelFocus,
    );
    if (speakVoice && cleanLine.trim().isNotEmpty && !muted) {
      unawaited(MascotSpeechLibrary.speak(cleanLine, voiceKey: voiceKey, muted: muted));
    }
  }

  /// Trigger a structured [MascotCue] from [MascotSpeechLibrary] with optional audio.
  MascotCue sayCue(
    MascotCueId id, {
    bool speakVoice = false,
    bool muted = false,
  }) {
    final cue = MascotSpeechLibrary.cueFor(id);
    say(
      mood: cue.mood,
      line: cue.displayBn,
      gesture: cue.gesture,
      voiceKey: cue.voiceKey,
      speakVoice: speakVoice,
      muted: muted,
    );
    return cue;
  }

  void react(GuideMood mood) {
    // Soft react: keep line unless empty; never restart a gag mid-way.
    if (state.gesture != GuideGesture.none) {
      state = state.copyWith(mood: mood, token: ++_token);
      return;
    }
    _token++;
    state = GuideState(
      mood: mood,
      gesture: GuideGesture.none,
      line: state.line,
      token: _token,
      levelFocus: state.levelFocus,
    );
  }

  void clearLine() {
    state = state.copyWith(line: '', mood: GuideMood.idle, gesture: GuideGesture.none, token: ++_token);
  }

  void clearEntrance() {
    if (state.entrance == null) return;
    state = state.copyWith(clearEntrance: true, token: ++_token);
  }

  void sleep() {
    if (state.gesture != GuideGesture.none) return;
    say(mood: GuideMood.sleep, line: '');
  }

  void wake({String line = ''}) => say(mood: GuideMood.wake, line: line);

  void endGesture() {
    if (state.gesture == GuideGesture.none) return;
    // An entrance line stays up until the host clears it.
    final keep = state.entrance != null;
    state = state.copyWith(
      gesture: GuideGesture.none,
      mood: keep ? state.mood : GuideMood.idle,
      line: keep ? state.line : '',
      token: ++_token,
    );
  }

  String _entranceLine = '';

  /// Line held until the host reveals the bubble (after body has settled).
  String get entranceLine => _entranceLine;

  /// First ladder open today → center welcome; else dock hi-pop.
  /// Body mood is set immediately; speech line stays empty until [revealEntranceLine].
  Future<GuideEntranceKind> beginLadderEntrance({bool muted = false}) async {
    _entranceMuted = muted;
    _entranceGesture = GuideGesture.none;
    final save = ref.read(gameSaveProvider);
    final cleared = save.rungProgress.values.where((v) => v == 'cleared').length;
    final before = _clearedAtEntrance;
    final streakBefore = _streakAtEntrance;
    _clearedAtEntrance = cleared;
    _streakAtEntrance = save.safeStreak;
    final prefs = await SharedPreferences.getInstance();
    final today = _dayKey(DateTime.now());
    final last = prefs.getString(_welcomeDayKey);
    final firstToday = last != today;
    if (before != null && !firstToday) {
      final climbed = cleared > before;
      final passedAgain = !climbed && streakBefore != null && save.safeStreak > streakBefore;
      final pool = climbed
          ? LadderComebackLines.climbed
          : (passedAgain ? LadderComebackLines.passedAgain : LadderComebackLines.same);
      _entranceLine = pool[_comebackPick++ % pool.length];
      _entranceVoiceKey = null;
      _entranceMood = climbed || passedAgain ? GuideMood.celebrate : GuideMood.inspire;
      _entranceGesture = climbed ? GuideGesture.spinHop : GuideGesture.none;
      say(mood: _entranceMood, line: '', entrance: GuideEntranceKind.comeback);
      return GuideEntranceKind.comeback;
    }
    if (firstToday) {
      await prefs.setString(_welcomeDayKey, today);
      final cue = MascotSpeechLibrary.cueFor(
        last == null ? MascotCueId.ladderWelcomeNew : MascotCueId.ladderWelcomeDaily,
      );
      _entranceLine = cue.displayBn;
      _entranceVoiceKey = cue.voiceKey;
      _entranceMood = GuideMood.wake;
      say(mood: GuideMood.wake, line: '', entrance: GuideEntranceKind.dailyWelcome);
      return GuideEntranceKind.dailyWelcome;
    }
    final cue = MascotSpeechLibrary.cueFor(MascotCueId.ladderWelcomeReturn);
    _entranceLine = cue.displayBn;
    _entranceVoiceKey = cue.voiceKey;
    _entranceMood = GuideMood.talk;
    say(mood: GuideMood.talk, line: '', entrance: GuideEntranceKind.hiPop);
    return GuideEntranceKind.hiPop;
  }

  void revealEntranceLine() {
    if (_entranceLine.isEmpty) return;
    final line = _entranceLine;
    final entrance = state.entrance;
    say(
      mood: _entranceMood,
      gesture: _entranceGesture,
      line: line,
      entrance: entrance,
      voiceKey: _entranceVoiceKey,
      speakVoice: true,
      muted: _entranceMuted,
    );
  }

  /// Minimum on-screen time before we may clear; voice wait is separate ([MascotSpeechLibrary.waitUntilQuiet]).
  Duration entranceHoldFor(String line, {bool reduce = false}) {
    if (reduce) return const Duration(milliseconds: 1400);
    final chars = line.trim().length;
    // Floor for reading; actual clear waits for voice to finish.
    final ms = (1400 + chars * 40).clamp(2000, 4000);
    return Duration(milliseconds: ms);
  }

  Future<void> comingSoon() async {
    sayCue(MascotCueId.ladderComingSoon);
  }

  Future<void> maybeInspire({Duration minGap = const Duration(seconds: 45)}) async {
    if (state.levelFocus) return;
    if (state.gesture != GuideGesture.none) return;
    if (MascotTalk.active.value || state.line.isNotEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastPoke) < const Duration(seconds: 12)) return;
    if (now.difference(_lastInspire) < minGap) return;
    final catalog = await ref.read(contentCatalogProvider.future);
    final lines = catalog.guideLines.where((g) => g.when == 'idle').toList();
    _lastInspire = now;
    if (lines.isEmpty) {
      sayCue(MascotCueId.ladderIdleLevel);
      return;
    }
    final pick = lines[_rng.nextInt(lines.length)];
    say(mood: GuideMood.inspire, line: MascotSpeechLibrary.toNaturalFieldBangla(pick.bnText));
  }

  /// Idle highlight on a playable level / gift — short, actionable field coach line.
  /// Never overrules other active lineman engagement (TTS speech, recent pro-tip poke, active dialogue).
  void nudgePlay({required bool gift}) {
    if (state.levelFocus) return;
    if (state.entrance != null) return;
    if (MascotTalk.active.value || state.line.isNotEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastPoke) < const Duration(seconds: 12)) return;
    if (state.gesture != GuideGesture.none) {
      state = state.copyWith(gesture: GuideGesture.none);
    }
    _lastInspire = now;
    sayCue(gift ? MascotCueId.ladderIdleGift : MascotCueId.ladderIdleLevel);
  }

  /// Gentle idle gesture — lean / peek / hop. Call after long quiet.
  Future<void> maybeFunnyIdle({Duration minGap = const Duration(seconds: 28)}) async {
    if (state.levelFocus) return;
    final now = DateTime.now();
    if (now.difference(_lastGag) < minGap) return;
    if (state.entrance != null) return;
    if (MascotTalk.active.value || state.line.isNotEmpty) return;
    if (now.difference(_lastPoke) < const Duration(seconds: 12)) return;
    if (state.mood == GuideMood.warn ||
        state.mood == GuideMood.fright ||
        state.mood == GuideMood.fallen ||
        state.mood == GuideMood.celebrate) {
      return;
    }
    _lastGag = now;
    final cue = MascotSpeechLibrary.randomFunnyIdle();
    say(mood: cue.mood, line: cue.displayBn, gesture: cue.gesture);
  }

  /// User tapped the mascot — react with an encouraging senior lineman field tip & voice!
  void onPoke({bool muted = false}) {
    if (state.levelFocus) return;
    if (state.entrance != null) return;
    final now = DateTime.now();
    if (now.difference(_lastPoke) < const Duration(milliseconds: 420)) return;
    _lastPoke = now;
    _lastGag = now;
    sayCue(MascotCueId.ladderPoke, speakVoice: true, muted: muted);
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final guideDirectorProvider = NotifierProvider<GuideDirector, GuideState>(GuideDirector.new);
