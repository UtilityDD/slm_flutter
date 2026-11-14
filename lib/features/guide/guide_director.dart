import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/en_digits.dart';
import '../auth/auth_provider.dart';
import '../game/game_save.dart';
import 'mascot_speech_library.dart';
import 'welcome_chooser.dart';

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
    'সাবাশ! এবার পরের ধাপে চলুন।',
    'দারুণ চলছে! থামবেন না।',
    'আরও একটা ধাপ পার! এগিয়ে চলুন।',
  ];
  /// A rung passed again (replay): praise without claiming a new rung.
  static const passedAgain = <String>[
    'সাবাশ! এবার পরের ধাপ।',
    'দারুণ চলছে! থামবেন না।',
  ];
  static const same = <String>[
    'আবার চেষ্টা করলেই হবে, আমি সঙ্গে আছি।',
    'কোন ধাপে যাবেন? আমি সঙ্গে আছি।',
    'একটু ভেবে নিয়ে আবার শুরু করুন।',
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

  /// Bumped by every [GuideDirector.say] (not by react/gesture beats), so the
  /// guide shows his bubble again for each new line, even a repeated one.
  final int lineToken;

  const GuideState({
    required this.mood,
    required this.gesture,
    required this.line,
    required this.token,
    this.entrance,
    this.levelFocus = false,
    this.lineToken = 0,
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
        lineToken: lineToken,
      );
}

class GuideDirector extends Notifier<GuideState> {
  /// Day of the last welcome, kept before [GameSave.lastLadderOpenMs] existed;
  /// read only so an older install is not greeted as a brand-new player.
  static const _welcomeDayKey = 'guide_last_welcome_day_v1';

  /// The clock for welcomes (tests pin it).
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  int _token = 0;
  int _lineToken = 0;
  DateTime _lastPoke = DateTime.fromMillisecondsSinceEpoch(0);
  bool _entranceMuted = false;
  String? _entranceVoiceKey;

  /// What the entrance says aloud when it differs from the caption (W10's
  /// caption carries the player's name; the clip is the name-free text).
  String? _entranceSpoken;
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
  GuideState build() {
    // Cancel any in-flight bubble dismiss when the provider goes away (tests).
    ref.onDispose(_abortBubbleDismiss);
    return GuideState.quiet;
  }

  int _bubbleDismissGen = 0;
  Timer? _bubbleDismissTimer;
  Completer<void>? _bubbleDismissGate;

  void _abortBubbleDismiss() {
    _bubbleDismissGen++;
    _bubbleDismissTimer?.cancel();
    _bubbleDismissTimer = null;
    final gate = _bubbleDismissGate;
    _bubbleDismissGate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  /// Cancelable sleep used by bubble auto-dismiss (safe under widget tests).
  Future<void> _dismissSleep(Duration d, int gen) async {
    if (gen != _bubbleDismissGen) return;
    final gate = Completer<void>();
    _bubbleDismissGate = gate;
    _bubbleDismissTimer?.cancel();
    _bubbleDismissTimer = Timer(d, () {
      if (!gate.isCompleted) gate.complete();
    });
    await gate.future;
  }

  void say({
    required GuideMood mood,
    required String line,
    GuideGesture gesture = GuideGesture.none,
    GuideEntranceKind? entrance,
    String? voiceKey,
    bool speakVoice = false,
    bool muted = false,
  }) {
    _abortBubbleDismiss();
    _token++;
    final myToken = _token;
    final cleanLine = enDigits(line);
    state = GuideState(
      mood: mood,
      gesture: gesture,
      line: cleanLine,
      token: _token,
      entrance: entrance,
      levelFocus: state.levelFocus,
      lineToken: ++_lineToken,
    );
    if (speakVoice && cleanLine.trim().isNotEmpty && !muted) {
      unawaited(MascotSpeechLibrary.speak(cleanLine, voiceKey: voiceKey, muted: muted));
    }
    // Praise / celebration bubbles clear after voice so they don't cover the
    // scene. Task prompts (talk / think / inspire / warn) stay until the next say.
    // Ladder entrance keeps its own hold/clear in LadderGuideHost.
    if (cleanLine.trim().isNotEmpty &&
        entrance == null &&
        (mood == GuideMood.glad || mood == GuideMood.celebrate)) {
      unawaited(_dismissBubbleWhenQuiet(token: myToken, line: cleanLine));
    }
  }

  /// Clears only the speech text (keeps mood/gesture) so the corner bubble goes away.
  void softClearLine() {
    _abortBubbleDismiss();
    if (state.line.isEmpty) return;
    state = state.copyWith(line: '', token: ++_token);
  }

  /// After [say]: wait for speech to finish (or a read hold when muted), then soft-clear.
  Future<void> _dismissBubbleWhenQuiet({required int token, required String line}) async {
    final gen = ++_bubbleDismissGen;
    // Callers often `say` then `speak` — give lips a moment to start.
    await _dismissSleep(const Duration(milliseconds: 280), gen);
    if (_token != token || gen != _bubbleDismissGen) return;

    var heard = MascotTalk.active.value;
    if (!heard) {
      for (var i = 0; i < 22; i++) {
        await _dismissSleep(const Duration(milliseconds: 50), gen);
        if (_token != token || gen != _bubbleDismissGen) return;
        if (MascotTalk.active.value) {
          heard = true;
          break;
        }
      }
    }

    if (heard) {
      await MascotSpeechLibrary.waitUntilQuiet();
      if (_token != token || gen != _bubbleDismissGen) return;
      final postMs = (380 + line.trim().length * 14).clamp(420, 1100);
      await _dismissSleep(Duration(milliseconds: postMs), gen);
    } else {
      // Muted / no engine: leave text long enough to read, then clear.
      final readMs = (900 + line.trim().length * 42).clamp(1200, 3200);
      await _dismissSleep(Duration(milliseconds: readMs), gen);
    }
    if (_token != token || gen != _bubbleDismissGen) return;
    if (state.line.isEmpty) return;
    softClearLine();
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
      lineToken: state.lineToken,
    );
  }

  void clearLine() {
    _abortBubbleDismiss();
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

  /// First ladder open today → center welcome; else dock hi-pop; back from a
  /// level in the same session → a quick comeback word.
  /// Body mood is set immediately; speech line stays empty until [revealEntranceLine].
  Future<GuideEntranceKind> beginLadderEntrance({bool muted = false}) async {
    _entranceMuted = muted;
    _entranceGesture = GuideGesture.none;
    _entranceSpoken = null;
    final now = clock();
    final saveCtl = ref.read(gameSaveProvider.notifier);
    final save = ref.read(gameSaveProvider);
    final cleared = save.rungProgress.values.where((v) => v == 'cleared').length;
    final before = _clearedAtEntrance;
    final streakBefore = _streakAtEntrance;
    _clearedAtEntrance = cleared;
    _streakAtEntrance = save.safeStreak;
    var lastOpen = save.lastLadderOpen;
    if (lastOpen == null) {
      final prefs = await SharedPreferences.getInstance();
      lastOpen = _parseDayKey(prefs.getString(_welcomeDayKey));
    }
    final firstToday = lastOpen == null || welcomeDaysBetween(lastOpen, now) != 0;
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
      await saveCtl.noteLadderOpen(now, consumeFlags: false);
      say(mood: _entranceMood, line: '', entrance: GuideEntranceKind.comeback);
      return GuideEntranceKind.comeback;
    }
    final l1Cleared = save.rungProgress.values.any((v) => v == 'cleared' || v == 'prove');
    final situation = chooseWelcome(
      now: now,
      lastLadderOpen: lastOpen,
      l1Cleared: l1Cleared,
      isFirstEver: lastOpen == null && !l1Cleared && save.playsByRung.isEmpty && save.points == 0,
      diedLastSession: save.diedLastSession,
      rankedUpSinceLastOpen: save.rankedUpSinceLastOpen,
      name: _playerName(),
    );
    await saveCtl.noteLadderOpen(now, consumeFlags: true);
    final cue = MascotSpeechLibrary.welcomeCue(situation);
    _entranceLine = MascotSpeechLibrary.welcomeCaption(situation, name: _playerName());
    _entranceSpoken = cue.displayBn == _entranceLine ? null : cue.displayBn;
    _entranceVoiceKey = cue.voiceKey;
    _entranceMood = cue.mood;
    final kind = firstToday ? GuideEntranceKind.dailyWelcome : GuideEntranceKind.hiPop;
    say(mood: _entranceMood, line: '', entrance: kind);
    return kind;
  }

  /// The signed-in player's name for W10 (null for guests or when unknown).
  String? _playerName() {
    try {
      final auth = ref.read(authProvider);
      if (!auth.isAuthenticated) return null;
      final name = auth.profile?.fullName?.trim() ?? '';
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDayKey(String? key) {
    if (key == null) return null;
    final p = key.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    return y == null || m == null || d == null ? null : DateTime(y, m, d);
  }

  void revealEntranceLine() {
    if (_entranceLine.isEmpty) return;
    final line = _entranceLine;
    final entrance = state.entrance;
    final spoken = _entranceSpoken;
    say(
      mood: _entranceMood,
      gesture: _entranceGesture,
      line: line,
      entrance: entrance,
      voiceKey: _entranceVoiceKey,
      speakVoice: spoken == null,
      muted: _entranceMuted,
    );
    if (spoken != null && !_entranceMuted) {
      unawaited(MascotSpeechLibrary.speak(spoken, voiceKey: _entranceVoiceKey));
    }
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
    sayCue(gift ? MascotCueId.ladderIdleGift : MascotCueId.ladderIdleLevel);
  }

  /// User tapped the mascot — react with an encouraging senior lineman field tip & voice!
  void onPoke({bool muted = false}) {
    if (state.levelFocus) return;
    if (state.entrance != null) return;
    final now = DateTime.now();
    if (now.difference(_lastPoke) < const Duration(milliseconds: 420)) return;
    _lastPoke = now;
    sayCue(MascotCueId.ladderPoke, speakVoice: true, muted: muted);
  }
}

final guideDirectorProvider = NotifierProvider<GuideDirector, GuideState>(GuideDirector.new);
