import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_sheet.dart';
import '../game/beat_fx.dart';
import '../game/game_exit_sheet.dart';
import '../game/game_save.dart';
import '../game/ladder_builder.dart';
import '../game/level_shell.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../home/bangla_read_aloud.dart';
import '../shell/shell_providers.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'ds_clearance.dart';
import 'ds_dress_up.dart';
import 'ds_pole_inspect.dart';
import 'adventure_map.dart';
import 'duty_slip_engine.dart';
import 'duty_slip_models.dart';
import 'duty_slip_voice.dart';

@immutable
class DsBoxDecodeKey {
  const DsBoxDecodeKey(this.inner, this.width, this.height, this.cover);
  final Object inner;
  final int width;
  final int height;
  final bool cover;

  @override
  bool operator ==(Object other) =>
      other is DsBoxDecodeKey &&
      other.inner == inner &&
      other.width == width &&
      other.height == height &&
      other.cover == cover;

  @override
  int get hashCode => Object.hash(inner, width, height, cover);
}

/// Decodes an image no larger than the device-pixel box it is shown in.
/// [cover] keeps the short side at least box size (BoxFit.cover); otherwise
/// the whole image fits the box (BoxFit.contain). Aspect ratio is kept and the
/// image is never upscaled, so what is painted looks the same as a full decode.
class DsBoxDecode extends ImageProvider<DsBoxDecodeKey> {
  const DsBoxDecode(this.inner, {required this.width, required this.height, required this.cover});

  final ImageProvider<Object> inner;
  final int width;
  final int height;
  final bool cover;

  /// [Image] for an asset shown in a [w] x [h] logical box.
  static Widget asset(
    BuildContext context,
    String path, {
    required double w,
    required double h,
    required BoxFit fit,
    double? width,
    double? height,
    ImageErrorWidgetBuilder? errorBuilder,
  }) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image(
      image: DsBoxDecode(
        AssetImage(path),
        width: (w * dpr).ceil(),
        height: (h * dpr).ceil(),
        cover: fit == BoxFit.cover,
      ),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  @override
  Future<DsBoxDecodeKey> obtainKey(ImageConfiguration configuration) {
    Completer<DsBoxDecodeKey>? completer;
    SynchronousFuture<DsBoxDecodeKey>? result;
    inner.obtainKey(configuration).then((Object key) {
      final k = DsBoxDecodeKey(key, width, height, cover);
      if (completer == null) {
        result = SynchronousFuture<DsBoxDecodeKey>(k);
      } else {
        completer.complete(k);
      }
    }, onError: (Object e, StackTrace s) => completer?.completeError(e, s));
    final sync = result;
    if (sync != null) return sync;
    completer = Completer<DsBoxDecodeKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(DsBoxDecodeKey key, ImageDecoderCallback decode) {
    Future<ui.Codec> boxed(ui.ImmutableBuffer buffer, {ui.TargetImageSizeCallback? getTargetSize}) {
      return decode(buffer, getTargetSize: (int iw, int ih) {
        if (iw <= 0 || ih <= 0) return const ui.TargetImageSize();
        final sx = width / iw;
        final sy = height / ih;
        final s = cover ? math.max(sx, sy) : math.min(sx, sy);
        if (s >= 1) return const ui.TargetImageSize();
        return ui.TargetImageSize(width: math.max(1, (iw * s).ceil()));
      });
    }

    return inner.loadImage(key.inner, boxed);
  }
}

/// "1.4/do/1" or "m1/gate" → module 1; null for an old level-number id.
int? _moduleOfRung(String rungId) {
  final m = RegExp(r'^m?(\d+)[./]').firstMatch(rungId);
  return m == null ? null : int.tryParse(m.group(1)!);
}

class DutySlipPage extends StatefulWidget {
  /// Kept for existing callers, which all pass `true`. The page always opens
  /// on the ladder; the old death cover is gone.
  final bool startOnRoad;

  /// Ladder index to open the map at (Home's gift chip); null: the current rung.
  final int? anchor;

  const DutySlipPage({super.key, this.startOnRoad = false, this.anchor});

  @override
  State<DutySlipPage> createState() => _DutySlipPageState();
}

class _FlyBit {
  _FlyBit({required this.id, required this.delta, required this.from, required this.to});
  final int id;
  final int delta;
  final Offset from;
  final Offset to;
}

class _DutySlipPageState extends State<DutySlipPage> with TickerProviderStateMixin {
  DutySlipEngine? _engine;
  final _tts = BanglaReadAloud();
  /// Bumped when HUD numbers change (score, level); rebuilds only the HUD.
  final _hudTick = ValueNotifier(0);
  /// Bumped when the HUD clock text or its overtime colour changes.
  final _scoreKey = GlobalKey();
  final _stackKey = GlobalKey();
  /// Level / job clock: a one-shot timer re-armed about once a second (just
  /// after the next play-second boundary), only while a level is on screen and
  /// the app is visible. Each tick credits the interval it waited; a tap or a
  /// hide mid-interval credits the part already elapsed ([_armWatch]).
  Timer? _clock;
  var _clockOn = false;
  var _armMs = 0;
  var _armFedMs = 0;
  final _armWatch = Stopwatch();
  var _jobAccMs = 0;
  var _appHidden = false;
  late final AppLifecycleListener _life;
  var _hudSig = 0;
  final _roadScroll = ValueNotifier<double>(0);
  late final AnimationController _shake;
  late final Animation<double> _shakeX;
  List<DsOption> _opts = [];
  String? _hint;
  var _hintOn = false;
  var _hintOpen = false;
  var _cardMistakes = 0;
  var _loading = true;
  /// Mute lives in [ZlMusic] (static), so it survives leaving and re-entering.
  bool get _muted => ZlMusic.muted;
  var _kitI = 0;
  final _yes = <String>{};
  var _callOpen = false;
  String? _ptwFeeder;
  String? _ptwPole;
  String? _ptwShift;
  var _ynKey = 0;
  var _clockHeld = false;
  var _flyId = 0;
  final _flies = ValueNotifier<List<_FlyBit>>(const []);

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12, end: -12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12, end: 7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeOut));
    _life = AppLifecycleListener(onHide: _onAppHide, onShow: _onAppShow);
    ZlFx.setMuted(ZlMusic.muted);
    _boot();
  }

  void _onAppHide() {
    _feedClock();
    _appHidden = true;
    _stopClock();
  }

  void _onAppShow() {
    _appHidden = false;
    final e = _engine;
    if (e != null) _syncClock(e);
  }

  /// Start or stop the clock to match the screen. Called from build, so every
  /// page transition re-checks it.
  void _syncClock(DutySlipEngine e) {
    final want = !_appHidden && e.clockScreen;
    if (want == _clockOn) return;
    if (!want) {
      _stopClock();
      return;
    }
    _clockOn = true;
    _jobAccMs = 0;
    _armClock(e);
  }

  void _stopClock() {
    _clockOn = false;
    _clock?.cancel();
    _clock = null;
    _armWatch.stop();
  }

  void _armClock(DutySlipEngine e) {
    _clock?.cancel();
    // Wake just after the mm:ss clock rolls over; otherwise once a second.
    final ms = (e.playClockRuns ? e.playMsToNextSecond + 8 : 1000).clamp(20, 1000);
    _armMs = ms;
    _armFedMs = 0;
    _armWatch
      ..reset()
      ..start();
    _clock = Timer(Duration(milliseconds: ms), _onClockTick);
  }

  void _onClockTick() {
    final e = _engine;
    if (!mounted || e == null || !_clockOn) return;
    _credit(_armMs - _armFedMs);
    _armFedMs = _armMs;
    _refreshHud();
    _armClock(e);
  }

  /// Credit the part of the current interval that has already passed, so a tap
  /// or leaving the app is timed to the millisecond, not to the tick.
  void _feedClock() {
    if (!_clockOn) return;
    final done = math.min(_armWatch.elapsedMilliseconds, _armMs);
    final d = done - _armFedMs;
    if (d <= 0) return;
    _armFedMs = done;
    _credit(d);
  }

  /// 2 job-seconds per 100 ms and the play clock in milliseconds: the same
  /// rates the old 100 ms periodic timer used.
  void _credit(int ms) {
    final e = _engine;
    if (e == null || ms <= 0) return;
    if (e.act == DsAct.done || e.act == DsAct.lethal) return;
    _jobAccMs += ms;
    final steps = _jobAccMs ~/ 100;
    if (steps > 0) {
      _jobAccMs -= steps * 100;
      e.addJobSeconds(2 * steps);
    }
    e.tickPlay(ms);
  }

  /// Rebuild the HUD (and/or its clock text) only if what it shows changed.
  void _refreshHud() {
    final e = _engine;
    if (!mounted || e == null) return;
    final sig = Object.hash(e.levelScore, e.quality, e.hudTotal, e.playing, e.listing, e.levelIndex, _runScore);
    if (sig != _hudSig) {
      _hudSig = sig;
      _hudTick.value++;
    }
  }

  Future<void> _boot() async {
    final pack = await DsPack.load();
    final engine = DutySlipEngine(pack);
    await engine.loadPersistedState();
    engine.openRoad();
    engine.ladderAnchor = widget.anchor;
    if (!mounted) return;
    setState(() {
      _engine = engine;
      _loading = false;
    });
    unawaited(ZlMusic.start());
  }

  /// This Do play's score: every chip that flies adds to it. When the play
  /// ends it replaces the rung's last score in the main ◆ ([_commitRun]),
  /// so the latest play counts and replays never farm points.
  int _runScore = 0;

  /// A Do play ended: its score plus [bonus] replaces the rung's last score
  /// in the main ◆. Leaving mid-level commits nothing.
  void _commitRun({int bonus = 0}) {
    final container = ProviderScope.containerOf(context);
    final rungId = container.read(gameSaveProvider).currentRungId;
    final score = _runScore + bonus;
    _runScore = 0;
    if (rungId.isEmpty) return;
    unawaited(container.read(gameSaveProvider.notifier).commitLevelScore(rungId, score));
  }

  /// Called by the ladder, which has already checked its lock and the verify gate.
  void _openLevel(int index) {
    final e = _engine;
    if (e == null || !e.onRoad) return;
    _runScore = 0;
    e.openLevel(index, fromLadder: true);
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _backToRoad() {
    final e = _engine;
    if (e == null) return;
    _feedClock();
    DsVoice.stop();
    _tts.stop();
    if (e.inField) {
      // Leaving the field night: drop the half-filled PTW and any open call.
      _ptwFeeder = null;
      _ptwPole = null;
      _ptwShift = null;
      _callOpen = false;
      _hintOn = false;
      _hintOpen = false;
      _hint = null;
    }
    e.backToRoad();
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.4, muted: _muted));
    _holdClock(false);
    setState(() {});
  }

  /// A safe (or risky) field night clears the rung that opened it — the
  /// module's rank gate. An unsafe night clears nothing.
  void _clearFieldRung() {
    final container = ProviderScope.containerOf(context);
    final rungId = container.read(gameSaveProvider).currentRungId;
    if (rungId.isEmpty) return;
    unawaited(container.read(gameSaveProvider.notifier).markRungCleared(rungId));
    _commitRun(bonus: 20);
  }

  void _finishSafeWalk() {
    final e = _engine;
    if (e == null || !e.showingDress) return;
    _feedClock();
    e.finishDress();
    _holdClock(false);
    final container = ProviderScope.containerOf(context);
    final rungId = container.read(gameSaveProvider).currentRungId;
    unawaited(container.read(gameSaveProvider.notifier).markRungCleared(rungId));
    _commitRun(bonus: 20);
    container.read(guideDirectorProvider.notifier).sayCue(
          MascotCueId.doLevelClear,
          speakVoice: false,
          muted: _muted,
        );
    unawaited(ZlFx.cue('sounds/quiz_complete.ogg', volume: 0.75, muted: _muted));
    // Return directly to the unified Ladder instead of the old medal result board.
    e.backToRoad();
    setState(() {});
  }

  Widget _photoLevel(DutySlipEngine e) {
    void onDelta(int delta, Offset global) => _flyDelta(delta, fromGlobal: global);
    if (e.level.number == 14) {
      return DsClearance(
        key: ValueKey(e.level.number),
        engine: e,
        onDone: _finishSafeWalk,
        muted: _muted,
        onSpeak: _speak,
        onDelta: onDelta,
      );
    }
    if (e.level.number >= 11 && e.level.number <= 13) {
      return DsPoleInspect(
        key: ValueKey(e.level.number),
        engine: e,
        onDone: _finishSafeWalk,
        muted: _muted,
        onSpeak: _speak,
        onDelta: onDelta,
      );
    }
    return DsDressUp(
      key: ValueKey(e.level.number),
      engine: e,
      onDone: _finishSafeWalk,
      muted: _muted,
      onSpeak: _speak,
      onDelta: onDelta,
      onBack: _backToRoad,
    );
  }

  void _openDress() {
    final e = _engine;
    if (e == null || !e.showingDressIntro) return;
    DsVoice.stop();
    _tts.stop();
    e.openDress();
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.45, muted: _muted));
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _startLevel() {
    final e = _engine;
    if (e == null || !e.listing) return;
    DsVoice.stop();
    _tts.stop();
    e.startLevelPlay();
    if (e.playing) {
      _holdClock(true);
      unawaited(ZlFx.cue('sounds/quiz_shuffle.ogg', muted: _muted));
    } else {
      _holdClock(true);
      unawaited(ZlFx.cue('sounds/quiz_flip.ogg', muted: _muted));
      unawaited(_speak('ডকেট পড়ে নিন।'));
    }
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _retryLevel() {
    final e = _engine;
    if (e == null || !e.showingResult) return;
    _runScore = 0;
    e.replayNow();
    if (e.playing) _holdClock(true);
    if (!e.showingDressIntro) unawaited(ZlFx.cue('sounds/quiz_shuffle.ogg', muted: _muted));
    setState(() {});
  }

  void _nextLevel() {
    final e = _engine;
    if (e == null || !e.showingResult) return;
    if (gameNeedsVerifyNow(context, e.level.number + 1)) {
      showVerifySheet(context);
      return;
    }
    e.nextAfterPass();
    _holdClock(false);
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', muted: _muted));
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  @override
  void dispose() {
    _life.dispose();
    _stopClock();
    _hudTick.dispose();
    _flies.dispose();
    _roadScroll.dispose();
    _shake.dispose();
    DsVoice.stop();
    _tts.stop();
    if (_clockHeld) ZlFx.releaseClock();
    ZlFx.stopClock();
    ZlMusic.stop();
    super.dispose();
  }

  void _holdClock(bool on) {
    if (on == _clockHeld) return;
    _clockHeld = on;
    if (on) {
      ZlFx.holdClock();
    } else {
      ZlFx.releaseClock();
    }
  }

  Future<void> _speak(String text) async {
    if (_muted || text.trim().isEmpty) return;
    DsTalk.begin();
    try {
      final clean = _engine?.fill(text) ?? text;
      final played = await DsVoice.play(clean, muted: _muted);
      if (!played) {
        await _tts.speakAwait(clean, rate: 0.42);
      }
    } finally {
      DsTalk.end();
    }
  }

  void _loadCard({required bool speak}) {
    final e = _engine;
    final s = e?.step;
    if (e == null || s == null) {
      setState(() {});
      return;
    }
    _yes.clear();
    _kitI = 0;
    _ynKey = 0;
    _hintOn = false;
    _hintOpen = false;
    _hint = null;
    _cardMistakes = 0;
    _opts = [...s.options]..shuffle();
    _holdClock(true);
    setState(() {});
    if (speak) unawaited(_speak(s.promptBn));
  }

  Offset _stackLocal(Offset global) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  Offset _scoreTarget() {
    final box = _scoreKey.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null) return const Offset(48, 56);
    final g = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    return stack.globalToLocal(g);
  }

  void _flyDelta(int delta, {Offset? fromGlobal}) {
    if (delta == 0) return;
    final size = MediaQuery.sizeOf(context);
    final origin = (fromGlobal != null && fromGlobal != Offset.zero)
        ? fromGlobal
        : Offset(size.width / 2, size.height * 0.55);
    final from = _stackLocal(origin);
    final to = _scoreTarget();
    final id = ++_flyId;
    // Only the fly overlay and the HUD rebuild; the game board below does not.
    _flies.value = [..._flies.value, _FlyBit(id: id, delta: delta, from: from, to: to)];
    // Callers may change the score right after this call; read it once they are done.
    scheduleMicrotask(_refreshHud);
    // Into this play's score (never below 0); the main ◆ changes when the play ends.
    _runScore = math.max(0, _runScore + delta);
    final container = ProviderScope.containerOf(context);
    container.read(guideDirectorProvider.notifier).react(delta > 0 ? GuideMood.glad : GuideMood.warn);
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _flies.value = [for (final f in _flies.value) if (f.id != id) f];
    });
  }

  Future<void> _commitLethalFall(DutySlipEngine e, DsResult r) async {
    final cause = (e.lethalReason ?? r.noteBn).trim();
    final container = ProviderScope.containerOf(context);
    // The rung being played (set by the ladder) says which module to fall to,
    // whichever legacy level it opened.
    final current = container.read(gameSaveProvider).currentRungId;
    final fromRung = _moduleOfRung(current);
    final module = fromRung ?? (e.levelIndex ~/ 20) + 1;
    final moduleFirst = '$module.1/learn';
    final rungId = fromRung != null ? current : '$module.${(e.levelIndex % 20) + 1}/do';
    final head = current.split('/').first;
    _commitRun();
    await container.read(gameSaveProvider.notifier).recordLethalDeath(
          cause: cause.isEmpty ? 'মারাত্মক ভুল' : cause,
          lessonId: head.contains('.') ? head : '${e.level.number}',
          rungId: rungId,
          moduleFirstRungId: moduleFirst,
        );
    if (!mounted) return;
    e.fallToModuleCheckpoint();
    setState(() {});
  }

  void _handle(DsResult r, {Offset? fromGlobal}) {
    final e = _engine;
    if (e == null) return;
    if (r.delta != 0) _flyDelta(r.delta, fromGlobal: fromGlobal);
    if (r.ok) {
      unawaited(ZlFx.cue('sounds/quiz_right.ogg', muted: _muted));
      HapticFeedback.lightImpact();
      if (e.act == DsAct.call) {
        _callOpen = false;
        unawaited(ZlFx.cue('sounds/complaint.ogg', volume: 0.85, muted: _muted));
        setState(() {});
        unawaited(_speak(e.activeCall?.lineBn ?? ''));
        return;
      }
      if (e.act == DsAct.done || e.act == DsAct.lethal) {
        _holdClock(false);
        unawaited(ZlFx.cue('sounds/quiz_complete.ogg', muted: _muted));
      }
      if (e.act == DsAct.done && e.level.isField) {
        // Safe or risky: the gate clears. Unsafe: no clear, but the play's score stands.
        if (e.grade() != DsGrade.unsafe) {
          _clearFieldRung();
        } else {
          _commitRun();
        }
      }
      _loadCard(speak: true);
    } else if (r.lethal || e.act == DsAct.lethal) {
      _holdClock(false);
      unawaited(ZlFx.cue('sounds/accident.ogg', muted: _muted));
      HapticFeedback.heavyImpact();
      setState(() {});
      unawaited(_speak(e.lethalReason ?? r.noteBn));
      unawaited(_commitLethalFall(e, r));
    } else {
      unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', muted: _muted));
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      _hintOn = true;
      _cardMistakes++;
      setState(() {});
      if (_cardMistakes == 1) {
        unawaited(_speak('না, হলো না!'));
      } else {
        _showHint();
      }
    }
  }

  void _showHint() {
    final e = _engine;
    final s = e?.step;
    if (!_hintOn || e == null || s == null) return;
    final text = e.fill(s.hintBn);
    final shown = text.isEmpty ? 'আবার ভেবে দেখুন।' : text;
    setState(() {
      _hintOpen = true;
      _hint = shown;
    });
    unawaited(_speak(shown));
  }

  void _pickSingle(String id, Offset global) {
    final e = _engine;
    if (e == null || e.act != DsAct.card) return;
    _feedClock();
    _handle(e.answerSingle(id), fromGlobal: global);
  }

  void _answerYn(bool take, Offset global) {
    final e = _engine;
    final s = e?.step;
    if (e == null || s == null || s.kind != DsKind.kit) return;
    if (_kitI >= _opts.length) return;
    _feedClock();
    final o = _opts[_kitI];
    final must = s.essential.contains(o.id);
    final ban = s.forbidden.contains(o.id);
    final ok = must ? take : ban ? !take : true;
    if (take) _yes.add(o.id);
    if (ok) {
      e.addScore(5);
      unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.55, muted: _muted));
      HapticFeedback.selectionClick();
      _flyDelta(5, fromGlobal: global);
    } else {
      e.addScore(-5);
      e.safety = (e.safety - 5).clamp(0, 100);
      e.jumpMinutes(5);
      unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', muted: _muted));
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      _flyDelta(-5, fromGlobal: global);
    }
    _kitI++;
    _ynKey++;
    if (_kitI >= _opts.length) {
      _handle(e.answerKit(_yes), fromGlobal: global);
    } else {
      setState(() {});
      unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.45, muted: _muted));
    }
  }

  void _tapPlan(String id, Offset global) {
    final e = _engine;
    if (e == null) return;
    _feedClock();
    final r = e.tapPlan(id);
    if (r.ok) {
      unawaited(ZlFx.cue('sounds/quiz_select.ogg', muted: _muted));
      if (r.streak >= 3) {
        unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.35, muted: _muted));
      }
      if (r.gift) {
        unawaited(ZlFx.cue('sounds/quiz_right.ogg', muted: _muted));
      }
      HapticFeedback.lightImpact();
      _flyDelta(r.delta, fromGlobal: global);
      if (e.showingResult) {
        _holdClock(false);
        final container = ProviderScope.containerOf(context);
        final rungId = container.read(gameSaveProvider).currentRungId;
        unawaited(container.read(gameSaveProvider.notifier).markRungCleared(rungId));
        _commitRun(bonus: 20);
        container.read(guideDirectorProvider.notifier).sayCue(
              MascotCueId.doLevelClear,
              speakVoice: false,
              muted: _muted,
            );
        e.backToRoad();
      }
    } else {
      unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', muted: _muted));
      if (e.level.living) {
        unawaited(ZlFx.cue('sounds/quiz_shuffle.ogg', volume: 0.55, muted: _muted));
      }
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      _flyDelta(r.delta, fromGlobal: global);
    }
    setState(() {});
  }

  Future<void> _confirmExit() async {
    // Back closes an open ladder card (reply card / lucky toolbox) before it asks to leave.
    if (AdventureMap.closeOpenCard()) return;
    final e = _engine;
    final onLadder = e == null || e.onRoad || e.covering || e.listing || e.showingResult;
    final bn = ProviderScope.containerOf(context).read(languageProvider);
    final ok = await showGameExitSheet(
      context,
      scope: onLadder ? GameExitScope.game : GameExitScope.level,
      bn: bn,
    );
    if (!mounted) return;
    if (!ok) return;
    if (onLadder) {
      Navigator.of(context).pop();
      return;
    }
    // Leave active step → road/ladder, not home.
    _backToRoad();
  }

  Widget _briefingStage(DutySlipEngine e) {
    return _OfficeStage(
      engine: e,
      feeder: _ptwFeeder,
      pole: _ptwPole,
      shift: _ptwShift,
      onPlan: _tapPlan,
      onOpenLevel: _openLevel,
      onBackRoad: _backToRoad,
      onOpenDress: _openDress,
      onStartLevel: _startLevel,
      onRetry: _retryLevel,
      onNextLevel: _nextLevel,
      muted: _muted,
      onSpeak: _speak,
      onDelta: _flyDelta,
      roadScroll: _roadScroll,
      onOpenPtw: () {
        unawaited(ZlFx.cue('sounds/quiz_flip.ogg', muted: _muted));
        e.openPtw();
        setState(() {});
      },
      onSetFeeder: (v) {
        unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.35, muted: _muted));
        setState(() => _ptwFeeder = v);
      },
      onSetPole: (v) {
        unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.35, muted: _muted));
        setState(() => _ptwPole = v);
      },
      onSetShift: (v) {
        unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.35, muted: _muted));
        setState(() => _ptwShift = v);
      },
      onSubmitPtw: () {
        if (_ptwFeeder == null ||
            _ptwFeeder!.isEmpty ||
            _ptwPole == null ||
            _ptwPole!.isEmpty ||
            _ptwShift == null ||
            _ptwShift!.isEmpty) {
          return;
        }
        final box = context.findRenderObject() as RenderBox?;
        final mid = box?.size.center(Offset.zero) ?? Offset.zero;
        final g = box?.localToGlobal(mid);
        _feedClock();
        final ok = e.submitPtw(feederPick: _ptwFeeder!, polePick: _ptwPole!, shiftPick: _ptwShift!);
        if (ok) {
          unawaited(ZlFx.cue('sounds/quiz_right.ogg', muted: _muted));
          _flyDelta(5, fromGlobal: g);
          _loadCard(speak: true);
        } else {
          unawaited(ZlFx.cue('sounds/quiz_wrong.ogg', muted: _muted));
          _shake.forward(from: 0);
          _flyDelta(-5, fromGlobal: g);
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _engine == null) {
      return const Scaffold(
        backgroundColor: SlmColors.navy950,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: SlmColors.gold300)),
      );
    }
    final e = _engine!;
    _syncClock(e);
    final jobIntro = e.listing && e.level.isJob;
    final dress = e.showingDress;
    final photoPlay = dress;
    // Level 6 opens straight into the dress game, so its intro never shows.
    final vanIntro = e.showingDressIntro && e.level.number >= 6 && e.level.number <= 14;
    final vanIntroScene = vanIntro && e.level.number > 6 && e.level.number <= 14;
    final bg = switch (e.act) {
      DsAct.briefing when e.briefingPage == 1 => 'assets/duty_slip/duty_fault_slip.jpg',
      DsAct.briefing when e.briefingPage == 2 => 'assets/duty_slip/duty_ptw_pad.jpg',
      _ when jobIntro => e.site.bg.isNotEmpty ? e.site.bg : 'assets/zero_loss/scene/bg_market_wire_down.webp',
      _ => e.site.bg,
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) _confirmExit();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: dress ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: ZlColors.bg,
          body: Stack(
          key: _stackKey,
          fit: StackFit.expand,
          children: [
            if (photoPlay)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shakeX,
                  builder: (_, child) => Transform.translate(offset: Offset(_shakeX.value, 0), child: child),
                  child: _photoLevel(e),
                ),
              )
            else if (vanIntroScene)
              Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _dressIntroArt(e.level.number),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x77000000), Color(0xDD000000)],
                      ),
                    ),
                  ),
                ],
              )
            else if (e.onRoad)
              const SizedBox.shrink()
            else
              Image.asset(bg, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.bg)),
            if (!dress && !vanIntro && !e.onRoad)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: e.act == DsAct.briefing && e.briefingPage > 0
                        ? const [Color(0x22000000), Color(0x99000000)]
                        : jobIntro
                            ? const [Color(0x4A000000), Color(0xB3000000)]
                            : const [Color(0x77000000), Color(0xDD000000)],
                  ),
                ),
              ),
            if (e.onRoad)
              Positioned.fill(child: _briefingStage(e))
            else
            SafeArea(
              child: Column(
                children: [
                  if (e.showHud)
                    ValueListenableBuilder<int>(
                      valueListenable: _hudTick,
                      builder: (_, _, _) => _Hud(
                        engine: e,
                        scoreKey: _scoreKey,
                        levelScore: _runScore,
                        muted: _muted,
                        onMute: () async {
                          final next = !_muted;
                          ZlFx.setMuted(next);
                          final done = ZlMusic.setMuted(next);
                          setState(() {});
                          if (next) _tts.stop();
                          await done;
                        },
                      ),
                    ),
                  if (e.stamps.contains('ptw'))
                    _PocketChip(feeder: e.feeder, alert: e.slashed.contains('feeder')),
                  Expanded(
                    child: dress
                        ? const IgnorePointer(child: SizedBox.expand())
                        : AnimatedBuilder(
                      animation: _shakeX,
                      builder: (_, child) => Transform.translate(offset: Offset(_shakeX.value, 0), child: child),
                      child: switch (e.act) {
                        DsAct.briefing => _briefingStage(e),
                        DsAct.card when e.step != null => _PlayCard(
                            engine: e,
                            step: e.step!,
                            pool: _opts,
                            kitIndex: _kitI,
                            hintOn: _hintOn,
                            hintOpen: _hintOpen,
                            hint: _hint,
                            ynKey: _ynKey,
                            onHint: _showHint,
                            onSingle: _pickSingle,
                            onYn: _answerYn,
                          ),
                        DsAct.call when e.activeCall != null => _CallBurst(
                            engine: e,
                            call: e.activeCall!,
                            open: _callOpen,
                            onOpen: () {
                              unawaited(ZlFx.cue('sounds/quiz_flip.ogg', muted: _muted));
                              setState(() => _callOpen = true);
                            },
                            onReply: (id, g) {
                              _feedClock();
                              _handle(e.answerCall(id), fromGlobal: g);
                            },
                          ),
                        DsAct.lethal || DsAct.done => SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: _Report(engine: e, onClose: () => Navigator.of(context).pop()),
                          ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<List<_FlyBit>>(
                valueListenable: _flies,
                builder: (_, flies, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [for (final f in flies) _FlyingScore(key: ValueKey(f.id), bit: f)],
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

class _FlyingScore extends StatelessWidget {
  final _FlyBit bit;
  const _FlyingScore({super.key, required this.bit});

  @override
  Widget build(BuildContext context) {
    final plus = bit.delta > 0;
    final label = plus ? '+${enDigits('${bit.delta}')} ◆' : '${enDigits('${bit.delta}')} ◆';
    final color = plus ? SlmColors.emerald300 : SoftDanger.ink;
    final borderColor = plus ? SlmColors.gold300 : SoftDanger.ink;
    return TweenAnimationBuilder<double>(
      key: ValueKey(bit.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 780),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) {
        final linearPos = Offset.lerp(bit.from, bit.to, t)!;
        final arcLift = -36.0 * math.sin(t * math.pi);
        final pos = Offset(linearPos.dx, linearPos.dy + arcLift);
        final scale = t < 0.2 ? (0.75 + 0.45 * (t / 0.2)) : (1.2 - 0.35 * ((t - 0.2) / 0.8));
        final opacity = t < 0.85 ? 1.0 : (1 - t) / 0.15;
        return Positioned(
          left: pos.dx - 42,
          top: pos.dy - 18,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: plus
                        ? const [Color(0xF20D3326), Color(0xF2081F18)]
                        : const [Color(0xF23B1219), Color(0xF2240A0E)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor, width: 1.4),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14),
                  ],
                ),
                child: Text(
                  label,
                  style: zlText(17, weight: FontWeight.w900, color: plus ? SlmColors.gold200 : SoftDanger.ink),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hud extends ConsumerWidget {
  final DutySlipEngine engine;
  final GlobalKey scoreKey;
  final bool muted;
  final VoidCallback onMute;
  /// This play's score: the pill shows it (chips fly into it).
  final int levelScore;
  const _Hud({
    required this.engine,
    required this.scoreKey,
    required this.levelScore,
    required this.muted,
    required this.onMute,
  });

  /// The same header as every level on the ladder: close · "L12" · ◆ · 💀.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = engine;
    final save = ref.watch(gameSaveProvider);
    final onLevel = e.playing || e.listing;
    final ctx = levelContextFor(ref.watch(builtLadderProvider).value, save.currentRungId);
    return UnifiedGameTopHud(
      scoreKey: scoreKey,
      badgeText: 'L${ctx?.ladderStep ?? e.level.number}',
      titleText: onLevel ? e.briefOf().title : '',
      stepOnly: true,
      closeIcon: Icons.close_rounded,
      muted: muted,
      levelScore: onLevel ? levelScore : null,
      onClose: () => Navigator.of(context).maybePop(),
      onToggleMute: onMute,
    );
  }
}

class _PocketChip extends StatelessWidget {
  final String feeder;
  final bool alert;
  const _PocketChip({required this.feeder, required this.alert});

  @override
  Widget build(BuildContext context) {
    final c = alert ? ZlColors.red : ZlColors.amber;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c),
      ),
      child: Text(feeder, style: zlText(13, weight: FontWeight.w800, color: c)),
    );
  }
}

class _OfficeStage extends StatelessWidget {
  final DutySlipEngine engine;
  final String? feeder;
  final String? pole;
  final String? shift;
  final void Function(String id, Offset global) onPlan;
  final void Function(int index) onOpenLevel;
  final VoidCallback onBackRoad;
  final VoidCallback onOpenDress;
  final VoidCallback onStartLevel;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;
  final VoidCallback onOpenPtw;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, {Offset? fromGlobal}) onDelta;
  final ValueNotifier<double> roadScroll;
  final ValueChanged<String> onSetFeeder;
  final ValueChanged<String> onSetPole;
  final ValueChanged<String> onSetShift;
  final VoidCallback onSubmitPtw;

  const _OfficeStage({
    required this.engine,
    required this.feeder,
    required this.pole,
    required this.shift,
    required this.onPlan,
    required this.onOpenLevel,
    required this.onBackRoad,
    required this.onOpenDress,
    required this.onStartLevel,
    required this.onRetry,
    required this.onNextLevel,
    required this.onOpenPtw,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
    required this.roadScroll,
    required this.onSetFeeder,
    required this.onSetPole,
    required this.onSetShift,
    required this.onSubmitPtw,
  });

  static const _ink = Color(0xFF1A140C);
  static const _wine = Color(0xFF7F1D1D);

  @override
  Widget build(BuildContext context) {
    final e = engine;
    if (e.briefingPage == 0) {
      return _PlanBoard(
        engine: e,
        onPlan: onPlan,
        onOpenLevel: onOpenLevel,
        onBackRoad: onBackRoad,
        onOpenDress: onOpenDress,
        onStartLevel: onStartLevel,
        onRetry: onRetry,
        onNextLevel: onNextLevel,
        muted: muted,
        onSpeak: onSpeak,
        onDelta: (delta, global) => onDelta(delta, fromGlobal: global),
        roadScroll: roadScroll,
      );
    }
    if (e.briefingPage == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.94, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                builder: (_, s, child) => Transform.scale(scale: s, child: child),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F1DE),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFC4B59A), width: 1.2),
                    boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 24, offset: Offset(0, 12))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('WBSEDCL', style: zlText(13, weight: FontWeight.w900, color: _wine)),
                          const Spacer(),
                          Text('DOCKET', style: zlText(12, weight: FontWeight.w800, color: _wine)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(height: 2.2, color: _wine),
                      const SizedBox(height: 14),
                      _DocketRow('সময়', e.clockLabel),
                      _DocketRow('জায়গা', e.site.nameBn),
                      _DocketRow('খুঁটি', e.site.pole),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(enDigits(e.site.introBn), style: zlText(19, weight: FontWeight.w800, color: _ink, height: 1.35)),
                        ),
                      ),
                      Text('ছিঁড়ে পড়া 11 কেভি কন্ডাক্টর', style: zlText(16, weight: FontWeight.w900, color: _ink)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ActionBtn(label: 'PTW নিন', onTap: onOpenPtw),
          ],
        ),
      );
    }
    final chips = <(String, String)>[
      ('feeder', e.feeder),
      ('feeder', e.fakes.first),
      ('pole', e.site.pole),
      ('pole', e.site.id == 'road' ? 'DP-09' : 'DP-17'),
      ('shift', 'আজ রাত'),
      ('shift', 'কাল সকাল'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6EC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFB7C4A8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PTW', textAlign: TextAlign.center, style: zlText(22, weight: FontWeight.w900, color: _ink)),
                  const SizedBox(height: 16),
                  _InkField(label: 'ফিডার', value: feeder),
                  _InkField(label: 'খুঁটি', value: pole),
                  _InkField(label: 'শিফট', value: shift),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final c in chips)
                _ChipPick(
                  label: c.$2,
                  onTap: () {
                    if (c.$1 == 'feeder') onSetFeeder(c.$2);
                    if (c.$1 == 'pole') onSetPole(c.$2);
                    if (c.$1 == 'shift') onSetShift(c.$2);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionBtn(label: 'PTW হাতে নিন', tone: _BtnTone.good, onTap: onSubmitPtw),
        ],
      ),
    );
  }
}

class _DocketRow extends StatelessWidget {
  final String k;
  final String v;
  const _DocketRow(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 72, child: Text(k, style: zlText(14, weight: FontWeight.w700, color: const Color(0xFF6B6256)))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 3),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1A140C), width: 1.1))),
              child: Text(v, style: zlText(19, weight: FontWeight.w900, color: const Color(0xFF1A140C))),
            ),
          ),
        ],
      ),
    );
  }
}

class _InkField extends StatelessWidget {
  final String label;
  final String? value;
  const _InkField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 72, child: Text(label, style: zlText(15, weight: FontWeight.w800, color: const Color(0xFF1A140C)))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1A140C), width: 1.5))),
              child: Text(
                filled ? value! : '—',
                style: zlText(18, weight: FontWeight.w900, color: filled ? const Color(0xFF1A140C) : const Color(0xFFB7B0A4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _bnNum(int n) => n.toString();

String _bnCount(int n) => _bnNum(n);

String _groupMark(DsJobGroup g) => '${g.title}  ·  ${_bnCount(g.count)} ধাপ';

class _PlanBoard extends StatelessWidget {
  final DutySlipEngine engine;
  final void Function(String id, Offset global) onPlan;
  final void Function(int index) onOpenLevel;
  final VoidCallback onBackRoad;
  final VoidCallback onOpenDress;
  final VoidCallback onStartLevel;
  final VoidCallback onRetry;
  final VoidCallback onNextLevel;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, Offset global) onDelta;
  final ValueNotifier<double> roadScroll;

  const _PlanBoard({
    required this.engine,
    required this.onPlan,
    required this.onOpenLevel,
    required this.onBackRoad,
    required this.onOpenDress,
    required this.onStartLevel,
    required this.onRetry,
    required this.onNextLevel,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
    required this.roadScroll,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    if (e.onRoad) {
      return AdventureMap(
        engine: e,
        onOpen: onOpenLevel,
        scrollOut: roadScroll,
        muted: muted,
      );
    }
    if (e.listing) {
      if (e.showingDressIntro) {
        return _DressIntro(
          key: ValueKey('dress-intro-${e.level.number}'),
          engine: e,
          onNext: onOpenDress,
          onBack: onBackRoad,
          muted: muted,
          onSpeak: onSpeak,
        );
      }
      if (e.level.isJob) {
        return _JobBriefBoard(engine: e, onNext: onStartLevel, onBack: onBackRoad, muted: muted, onSpeak: onSpeak);
      }
      return _BriefBoard(engine: e, onNext: onStartLevel, onBack: onBackRoad, muted: muted, onSpeak: onSpeak);
    }
    if (e.playing) return _PlayBoard(engine: e, onPlan: onPlan);
    return _ResultBoard(engine: e, onNext: onNextLevel, onRetry: onRetry, onBack: onBackRoad, muted: muted);
  }
}

class _PaperCard extends StatelessWidget {
  final Widget child;
  final GestureTapDownCallback? onTapDown;
  const _PaperCard({required this.child, this.onTapDown});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6E9C8),
      elevation: 6,
      shadowColor: const Color(0x88000000),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTapDown: onTapDown,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFC4B59A), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _RoundArrow({required this.onTap, this.icon = Icons.arrow_forward_rounded});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ZlColors.amber, width: 1.6),
          ),
          child: Icon(icon, size: 30, color: ZlColors.amber),
        ),
      ),
    );
  }
}

class _FloatArrow extends StatelessWidget {
  final VoidCallback onTap;
  final double reveal;
  final IconData icon;
  const _FloatArrow({required this.onTap, this.reveal = 1, this.icon = Icons.arrow_forward_rounded});

  @override
  Widget build(BuildContext context) {
    final a = reveal.clamp(0.0, 1.0);
    return IgnorePointer(
      ignoring: a < 0.96,
      child: Opacity(
        opacity: a,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - a)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: _RoundArrow(onTap: onTap, icon: icon),
          ),
        ),
      ),
    );
  }
}

class _JobBriefBoard extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  const _JobBriefBoard({
    required this.engine,
    required this.onNext,
    required this.onBack,
    required this.muted,
    required this.onSpeak,
  });

  @override
  State<_JobBriefBoard> createState() => _JobBriefBoardState();
}

class _JobBriefBoardState extends State<_JobBriefBoard> with TickerProviderStateMixin {
  late final AnimationController _run;
  late final AnimationController _insist;
  late final Animation<double> _insistScale;
  final _pinged = <int>{};
  var _page = 0;
  var _said = false;
  int? _openGroup;
  int? _openStep;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..addListener(_onTick)
      ..forward();
    _insist = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _insistScale = _insist.drive(Tween<double>(begin: 1, end: 1.03));
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.48, muted: widget.muted));
    Future<void>.delayed(const Duration(milliseconds: 480), () {
      if (!mounted || _said) return;
      _said = true;
      unawaited(widget.onSpeak('আসল কাজ। 23 ধাপ। মাঠে তার ছিঁড়ে পড়ে আছে। শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।'));
    });
  }

  void _onTick() {
    for (var i = 0; i < dsJobGroups.length; i++) {
      if (_run.value >= _btnStart(i) && _pinged.add(i)) {
        unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.38, muted: widget.muted));
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (slmLoopsOn(context)) {
      if (!_insist.isAnimating) _insist.repeat(reverse: true);
    } else {
      _insist
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _run.dispose();
    _insist.dispose();
    super.dispose();
  }

  double _span(double t, double a, double b, {Curve curve = Curves.easeOutCubic}) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  }

  static double _btnStart(int i) => 0.22 + i * 0.12;

  double _btnPunch(int i) => _span(_run.value, _btnStart(i), _btnStart(i) + 0.14, curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final plan = e.tonightPlan;
    return AnimatedBuilder(
      animation: _run,
      builder: (_, _) {
        final next = _span(_run.value, 0.88, 1.00);
        final arrow = _page == 2
            ? _FloatArrow(onTap: widget.onNext)
            : _page == 1
                ? _FloatArrow(onTap: _toHint)
                : _openGroup == null
                    ? _FloatArrow(reveal: next, onTap: _toReview)
                    : const SizedBox.shrink();
        return _IntroFrame(
          title: e.briefOf().title,
          onBack: () {
            if (_openStep != null) {
              setState(() => _openStep = null);
              return;
            }
            if (_openGroup != null) {
              _closeGroup();
              return;
            }
            if (_page == 2) {
              setState(() {
                _page = 1;
                _openStep = null;
              });
              return;
            }
            if (_page == 1) {
              setState(() {
                _page = 0;
                _openStep = null;
              });
              return;
            }
            widget.onBack();
          },
          next: arrow,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 480),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim);
              return FadeTransition(opacity: anim, child: SlideTransition(position: slide, child: child));
            },
            child: _page == 2
                ? _GuidePane(
                    key: const ValueKey('job-hint'),
                    body: e.briefOf().body,
                    bloom: 1,
                  )
                : _page == 1
                    ? _review(plan)
                    : _asolPage(plan),
          ),
        );
      },
    );
  }

  Widget _asolPage(List<DsPlanItem> plan) {
    final group = _openGroup == null ? null : dsJobGroups[_openGroup!];
    return Stack(
      key: const ValueKey('job-asol'),
      children: [
        Column(
          children: [
            _asolHead(
              below: group == null
                  ? Text(
                      'শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।',
                      textAlign: TextAlign.center,
                      style: zlText(15, weight: FontWeight.w600, height: 1.45, color: const Color(0xFFD8CDB2)),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                      child: _GroupSubhead(label: _groupMark(group)),
                    ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: group == null ? _groupList() : _groupSteps(plan, group, _openGroup!),
              ),
            ),
          ],
        ),
        if (_openStep != null && _openStep! < plan.length)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _jobFocus(plan),
            ),
          ),
      ],
    );
  }

  Widget _groupList() {
    return ListView(
      key: const ValueKey('job-groups'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [for (var g = 0; g < dsJobGroups.length; g++) _groupBtn(g)],
    );
  }

  Widget _groupSteps(List<DsPlanItem> plan, DsJobGroup group, int g) {
    return ListView.builder(
      key: ValueKey('job-steps-$g'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: group.count,
      itemBuilder: (_, k) {
        final i = group.start + k;
        if (i < 0 || i >= plan.length) return const SizedBox.shrink();
        return _jobStep(plan, i, k);
      },
    );
  }

  Widget _jobFocus(List<DsPlanItem> plan) {
    final i = _openStep!;
    final (a, b) = _stepRange();
    return _StepFocus(
      item: plan[i],
      onClose: () => setState(() => _openStep = null),
      onPrev: i > a ? () => _navStep(-1) : null,
      onNext: i < b - 1 ? () => _navStep(1) : null,
    );
  }

  Widget _groupBtn(int g) {
    final group = dsJobGroups[g];
    final punch = _btnPunch(g);
    return Opacity(
      opacity: punch.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - punch.clamp(0.0, 1.0))),
        child: Transform.scale(
          scale: 0.86 + 0.14 * punch.clamp(0.0, 1.2),
          // The 3% "tap me" pulse repaints only; the board does not rebuild.
          child: ScaleTransition(
            scale: _insistScale,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: punch < 0.55 ? null : () => _toggleGroup(g),
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)],
                      ),
                      border: Border.all(color: const Color(0xFF5C4316), width: 1.15),
                      boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _groupMark(group),
                            style: zlText(16, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF3A2A10)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobStep(List<DsPlanItem> plan, int index, int local) {
    if (index < 0 || index >= plan.length) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + local * 70),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 16 * (1 - t.clamp(0.0, 1.0))), child: child),
      ),
      child: GestureDetector(
        onTap: () => _tapStep(index, plan[index].whyBn),
        child: _StepCard(
          item: plan[index],
          punch: 1,
          focused: _openStep == index,
        ),
      ),
    );
  }

  Widget _asolHead({required Widget below}) {
    return Column(
      children: [
        Text(
          '23 ধাপ। মাঠে তার ছিঁড়ে পড়ে আছে।',
          textAlign: TextAlign.center,
          style: zlText(16, weight: FontWeight.w700, height: 1.4, color: const Color(0xFFE8D9A8)),
        ),
        const SizedBox(height: 8),
        below,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _review(List<DsPlanItem> plan) {
    return Stack(
      key: const ValueKey('job-review'),
      children: [
        Column(
          children: [
            _asolHead(
              below: Text(
                'শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।',
                textAlign: TextAlign.center,
                style: zlText(15, weight: FontWeight.w600, height: 1.45, color: const Color(0xFFD8CDB2)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: plan.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _tapStep(i, plan[i].whyBn),
                  child: _StepCard(item: plan[i], punch: 1, focused: _openStep == i),
                ),
              ),
            ),
          ],
        ),
        if (_openStep != null && _openStep! < plan.length)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: _jobFocus(plan),
            ),
          ),
      ],
    );
  }

  void _toggleGroup(int g) {
    setState(() {
      _openGroup = g;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.48, muted: widget.muted));
    HapticFeedback.mediumImpact();
    unawaited(widget.onSpeak(dsJobGroups[g].title));
  }

  void _closeGroup() {
    if (_openGroup == null) return;
    setState(() {
      _openGroup = null;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.42, muted: widget.muted));
    HapticFeedback.selectionClick();
  }

  (int, int) _stepRange() {
    final n = widget.engine.tonightPlan.length;
    if (_page == 1) return (0, n);
    final g = _openGroup;
    if (g == null) return (0, n);
    final group = dsJobGroups[g];
    return (group.start, group.start + group.count);
  }

  void _openStepAt(int i) {
    final plan = widget.engine.tonightPlan;
    if (i < 0 || i >= plan.length) return;
    setState(() => _openStep = i);
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    final why = plan[i].whyBn;
    if (why.isNotEmpty) unawaited(widget.onSpeak(why));
  }

  void _navStep(int delta) {
    if (_openStep == null) return;
    final (a, b) = _stepRange();
    final n = _openStep! + delta;
    if (n < a || n >= b) return;
    _openStepAt(n);
  }

  void _tapStep(int i, String why) {
    if (_openStep == i) {
      setState(() => _openStep = null);
      return;
    }
    _openStepAt(i);
  }

  void _toReview() {
    setState(() {
      _page = 1;
      _openGroup = null;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    unawaited(widget.onSpeak('শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।'));
  }

  void _toHint() {
    setState(() {
      _page = 2;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    final hint = widget.engine.briefOf().body.trim();
    if (hint.isNotEmpty) unawaited(widget.onSpeak(hint));
  }
}

class _IntroFrame extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget body;
  final Widget next;
  const _IntroFrame({
    required this.title,
    required this.onBack,
    required this.body,
    required this.next,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: zlText(28, weight: FontWeight.w900, height: 1.28, color: const Color(0xFFF6E7B0)).copyWith(
                shadows: const [Shadow(color: Color(0x66C9A227), blurRadius: 12)],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: body),
                Positioned(right: 10, bottom: 6, child: next),
                Positioned(
                  left: 10,
                  bottom: 6,
                  child: _FloatArrow(icon: Icons.arrow_back_rounded, onTap: onBack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DressIntro extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool muted;
  final Future<void> Function(String text) onSpeak;

  const _DressIntro({
    super.key,
    required this.engine,
    required this.onNext,
    required this.onBack,
    required this.muted,
    required this.onSpeak,
  });

  @override
  State<_DressIntro> createState() => _DressIntroState();
}

class _DressIntroState extends State<_DressIntro> {
  var _said = false;

  @override
  void initState() {
    super.initState();
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.48, muted: widget.muted));
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (!mounted || _said) return;
      _said = true;
      final line = widget.engine.briefOf().body.trim();
      if (line.isNotEmpty) unawaited(widget.onSpeak(line));
    });
  }

  @override
  Widget build(BuildContext context) {
    final brief = widget.engine.briefOf();
    final van = widget.engine.level.number >= 6 && widget.engine.level.number <= 14;
    final yardCard = widget.engine.level.number == 6;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IntroFrame(
          title: brief.title,
          onBack: widget.onBack,
          next: _FloatArrow(onTap: widget.onNext),
          body: yardCard
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 128),
                  child: Image.asset(
                    _dressIntroArt(6),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                )
              : van
                  ? const SizedBox.expand()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 168),
                      child: Image.asset(
                        _dressIntroArt(widget.engine.level.number),
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                      ),
                    ),
        ),
        if (yardCard || !van)
          Positioned(
            left: 8,
            bottom: 72,
            child: IgnorePointer(
              child: DsCoach(mood: DsCoachMood.talk, line: brief.body, bubbleWidth: 228),
            ),
          ),
        if (van && !yardCard)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, 0.22),
                child: DsCoach(
                  mood: DsCoachMood.talk,
                  line: brief.body,
                  bubbleWidth: 280,
                  sprite: 176,
                  centered: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _dressIntroArt(int level) => switch (level) {
      2 => 'assets/duty_slip/dress/tray_elec_helmet.webp',
      3 => 'assets/duty_slip/dress/tray_rubber_gloves.webp',
      4 => 'assets/duty_slip/dress/tray_harness.webp',
      5 => 'assets/duty_slip/dress/kit_ready.webp',
      6 => 'assets/zero_loss/scene/prop_truck.webp',
      7 => 'assets/zero_loss/scene/bg_market_wire_down.webp',
      8 => 'assets/zero_loss/scene/bg_dtr_structure.webp',
      9 => 'assets/zero_loss/scene/bg_pole_storm.webp',
      10 => 'assets/zero_loss/scene/bg_tree_on_line.webp',
      11 => 'assets/zero_loss/scene/pole11_title.jpg',
      12 => 'assets/zero_loss/scene/pole12_title.jpg',
      13 => 'assets/zero_loss/scene/pole13_title.jpg',
      14 => 'assets/zero_loss/scene/pole14_open.jpg',
      _ => 'assets/duty_slip/dress/tray_shirt.webp',
    };

class _BriefBoard extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  const _BriefBoard({
    required this.engine,
    required this.onNext,
    required this.onBack,
    required this.muted,
    required this.onSpeak,
  });

  @override
  State<_BriefBoard> createState() => _BriefBoardState();
}

class _BriefBoardState extends State<_BriefBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _run;
  final _pinged = <int>{};
  var _said = false;
  var _nextCue = false;
  var _showBody = false;
  int? _open;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200));
    _run.addListener(_onTick);
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.48, muted: widget.muted));
    _run.forward();
    Future<void>.delayed(const Duration(milliseconds: 520), () {
      if (!mounted || _said) return;
      _said = true;
      final title = widget.engine.briefOf().title.trim();
      if (title.isNotEmpty) unawaited(widget.onSpeak(title));
    });
  }

  void _onTick() {
    final n = widget.engine.level.isLetters
        ? dsSafeHome.length
        : widget.engine.briefOf().stamps.length;
    for (var i = 0; i < n; i++) {
      if (_run.value >= _cardStart(i) && _pinged.add(i)) {
        unawaited(ZlFx.cue('sounds/quiz_select.ogg', volume: 0.42, muted: widget.muted));
        HapticFeedback.mediumImpact();
      }
    }
    if (_run.value >= 0.94 && !_nextCue) {
      _nextCue = true;
      unawaited(ZlFx.cue('sounds/quiz_complete.ogg', volume: 0.32, muted: widget.muted));
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  double _span(double t, double a, double b, {Curve curve = Curves.easeOutCubic}) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final brief = e.briefOf();
    return AnimatedBuilder(
      animation: _run,
      builder: (_, _) {
        final t = _run.value;
        final line = _span(t, 0.00, 0.16);
        final chip = _span(t, 0.08, 0.24);
        final bloom = _span(t, 0.10, 0.42, curve: Curves.easeOut);
        final titleIn = _span(t, 0.18, 0.40);
        final next = _span(t, 0.93, 1.00);
        return _IntroFrame(
          title: brief.title,
          onBack: () {
            if (_showBody) {
              setState(() {
                _showBody = false;
                _open = null;
              });
              return;
            }
            widget.onBack();
          },
          next: _FloatArrow(
            reveal: _showBody ? 1 : next,
            onTap: _showBody ? widget.onNext : _onArrow,
          ),
          body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 520),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _showBody
                      ? _GuidePane(
                          key: const ValueKey('guide'),
                          body: brief.body,
                          bloom: 1,
                        )
                      : _ListPane(
                          key: const ValueKey('list'),
                          engine: e,
                          brief: brief,
                          chip: chip,
                          line: line,
                          bloom: bloom,
                          titleIn: titleIn,
                          next: next,
                          open: _open,
                          punch: _cardPunch,
                          onTapStep: _tapStep,
                          onCloseStep: _closeStep,
                          onNext: _onArrow,
                        ),
                ),
        );
      },
    );
  }

  void _onArrow() {
    final body = widget.engine.briefOf().body.trim();
    if (body.isNotEmpty && !_showBody) {
      setState(() {
        _showBody = true;
        _open = null;
      });
      unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.5, muted: widget.muted));
      HapticFeedback.mediumImpact();
      unawaited(widget.onSpeak(body));
      return;
    }
    widget.onNext();
  }

  void _closeStep() {
    if (_open == null) return;
    setState(() => _open = null);
    HapticFeedback.selectionClick();
  }

  void _tapStep(int i, String why) {
    if (_open == i) {
      _closeStep();
      return;
    }
    setState(() => _open = i);
    unawaited(ZlFx.cue('sounds/quiz_flip.ogg', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    if (why.isNotEmpty) unawaited(widget.onSpeak(why));
  }

  static double _cardStart(int i) => 0.46 + i * 0.055;

  double _cardPunch(int i) {
    final start = _cardStart(i);
    return _span(_run.value, start, start + 0.09, curve: Curves.easeOutBack);
  }
}

class _BriefBloom extends StatelessWidget {
  final double bloom;
  const _BriefBloom({required this.bloom});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: bloom * 0.9,
      child: Transform.scale(
        scale: 0.55 + bloom * 0.55,
        child: Container(
          width: 240,
          height: 240,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x33FBBF24), Color(0x14F59E0B), Color(0x00000000)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListPane extends StatelessWidget {
  final DutySlipEngine engine;
  final DsBrief brief;
  final double chip;
  final double line;
  final double bloom;
  final double titleIn;
  final double next;
  final int? open;
  final double Function(int i) punch;
  final void Function(int i, String why) onTapStep;
  final VoidCallback onCloseStep;
  final VoidCallback onNext;

  const _ListPane({
    super.key,
    required this.engine,
    required this.brief,
    required this.chip,
    required this.line,
    required this.bloom,
    required this.titleIn,
    required this.next,
    required this.open,
    required this.punch,
    required this.onTapStep,
    required this.onCloseStep,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    return Stack(
      alignment: Alignment.center,
      children: [
        _BriefBloom(bloom: bloom),
        Positioned.fill(
          child: Stack(
            children: [
                  if (e.level.isLetters)
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                      itemCount: dsSafeHome.length,
                      itemBuilder: (_, i) {
                        final item = dsSafeHome[i];
                        final p = punch(i);
                        return IgnorePointer(
                          ignoring: p < 0.55 || open != null,
                          child: GestureDetector(
                            onTap: () => onTapStep(i, item.whyBn),
                            child: _StepCard(item: item, punch: p, focused: open == i),
                          ),
                        );
                      },
                    )
                  else
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < brief.stamps.length; i++)
                            Opacity(
                              opacity: punch(i).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.7 + 0.3 * punch(i),
                                child: _BriefStamp(label: brief.stamps[i]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (open != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 80,
                      child: _StepFocus(
                        item: dsSafeHome[open!],
                        onClose: onCloseStep,
                        onPrev: open! > 0 ? () => onTapStep(open! - 1, dsSafeHome[open! - 1].whyBn) : null,
                        onNext: open! < dsSafeHome.length - 1
                            ? () => onTapStep(open! + 1, dsSafeHome[open! + 1].whyBn)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _GuidePane extends StatelessWidget {
  final String body;
  final double bloom;
  const _GuidePane({super.key, required this.body, required this.bloom});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _BriefBloom(bloom: bloom),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 88),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, 22 * (1 - t)), child: child),
            ),
            child: Center(
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: zlText(24, weight: FontWeight.w700, height: 1.55, color: const Color(0xFFF6E7B0)).copyWith(
                  shadows: const [Shadow(color: Color(0x66C9A227), blurRadius: 12)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupSubhead extends StatelessWidget {
  final String label;
  const _GroupSubhead({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)],
        ),
        border: Border.all(color: const Color(0xFF5C4316), width: 1.15),
        boxShadow: const [BoxShadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: zlText(16, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final DsPlanItem item;
  final double punch;
  final bool focused;
  const _StepCard({required this.item, required this.punch, required this.focused});

  @override
  Widget build(BuildContext context) {
    final enter = punch.clamp(0.0, 1.0);
    return Opacity(
      opacity: enter,
      child: Transform.translate(
        offset: Offset(0, 48 * (1 - enter)),
        child: Transform.scale(
          scale: 0.7 + 0.3 * punch,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: focused
                    ? const [Color(0xFFFFF3C4), Color(0xFFE0B13A), Color(0xFF8A5A10)]
                    : const [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)],
              ),
              border: Border.all(
                color: focused ? const Color(0xFFF6E7B0) : const Color(0xFF5C4316),
                width: focused ? 1.4 : 1,
              ),
              boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1)],
            ),
            child: Text(
              enDigits(item.labelBn),
              textAlign: TextAlign.center,
              style: zlText(15, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepFocus extends StatelessWidget {
  final DsPlanItem item;
  final VoidCallback onClose;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const _StepFocus({required this.item, required this.onClose, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, s, child) => Opacity(
        opacity: s,
        child: Transform.scale(scale: 0.94 + 0.06 * s, child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onClose,
                child: const ColoredBox(color: Color(0xCC050A14)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StepNavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
                    Expanded(
                      child: Align(
                        child: GestureDetector(
                          onHorizontalDragEnd: (d) {
                            final v = d.primaryVelocity ?? 0;
                            if (v < -240) onNext?.call();
                            if (v > 240) onPrev?.call();
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFF3C4), Color(0xFFE0B13A), Color(0xFF8A5A10)],
                              ),
                              border: Border.all(color: const Color(0xFFF6E7B0), width: 1.4),
                              boxShadow: const [
                                BoxShadow(color: Color(0x88FBBF24), blurRadius: 22),
                                BoxShadow(color: Color(0x88000000), offset: Offset(0, 8), blurRadius: 18),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 380),
                                  child: ListView(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.fromLTRB(16, 16, 36, 16),
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: Column(
                                          key: ValueKey(item.id),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (item.icon.isNotEmpty)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: ColoredBox(
                                                  color: const Color(0x22000000),
                                                  child: DsBoxDecode.asset(
                                                    context,
                                                    item.icon,
                                                    w: MediaQuery.sizeOf(context).width,
                                                    h: 120,
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, _, _) => const SizedBox(
                                                      height: 72,
                                                      child: Icon(Icons.image_rounded, color: Color(0xFF5C4316), size: 36),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (item.icon.isNotEmpty) const SizedBox(height: 14),
                                            Text(
                                              enDigits(item.labelBn),
                                              textAlign: TextAlign.center,
                                              style: zlText(18, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
                                            ),
                                            if (item.whyBn.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                enDigits(item.whyBn),
                                                textAlign: TextAlign.center,
                                                style: zlText(15, weight: FontWeight.w600, height: 1.45, color: const Color(0xFF3A2A10)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    onPressed: onClose,
                                    icon: const Icon(Icons.close_rounded, color: Color(0xFF3A2A10), size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _StepNavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Opacity(
            opacity: on ? 1 : 0.28,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ZlColors.amber, width: 1.5),
              ),
              child: Icon(icon, size: 28, color: ZlColors.amber),
            ),
          ),
        ),
      ),
    );
  }
}

class _BriefStamp extends StatelessWidget {
  final String label;
  const _BriefStamp({required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)],
        ),
        border: Border.all(color: const Color(0xFF5C4316), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1)],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: zlText(14, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
      ),
    );
  }
}

class _DealDeck extends StatelessWidget {
  final Animation<double> animation;
  const _DealDeck({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final left = (1 - (animation.value / 0.55)).clamp(0.0, 1.0);
        return SizedBox(
          height: 8 + 34 * left,
          child: Opacity(
            opacity: left,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 210,
                height: 34 * left,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        top: i * 5.0 * left,
                        left: 12.0 + i * 6,
                        right: 12.0 + (2 - i) * 6,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color.lerp(const Color(0xFF1B2740), ZlColors.amber, i * 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ZlColors.amber.withValues(alpha: 0.45)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DealCard extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final int count;
  final Widget child;
  const _DealCard({required this.animation, required this.index, required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    final side = index.isEven ? 1.0 : -1.0;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final u = animation.value;
        final start = count <= 1 ? 0.0 : (index / count) * 0.62;
        final raw = ((u - start) / 0.38).clamp(0.0, 1.0);
        final drop = raw == 0 ? 0.0 : Curves.easeOutBack.transform(raw);
        return IgnorePointer(
          ignoring: raw < 0.82,
          child: Opacity(
            opacity: raw == 0 ? 0 : raw.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(side * 18 * (1 - raw), -72 * (1 - drop)),
              child: Transform.rotate(angle: side * 0.06 * (1 - raw), child: child),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PickedStrip extends StatefulWidget {
  final DutySlipEngine engine;
  const _PickedStrip({required this.engine});

  @override
  State<_PickedStrip> createState() => _PickedStripState();
}

class _PickedStripState extends State<_PickedStrip> {
  final _scroll = ScrollController();
  var _shown = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.engine.planNext;
    _keepEnd();
  }

  @override
  void didUpdateWidget(covariant _PickedStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.engine.planNext != _shown) {
      _shown = widget.engine.planNext;
      _keepEnd();
    }
  }

  void _keepEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final n = engine.planNext;
    if (n == 0) return const SizedBox(height: 8);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemCount: n,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: ZlColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ZlColors.green.withValues(alpha: 0.55)),
          ),
          child: Text(
            engine.level.isLetters ? enDigits(engine.currentDeck[i].labelBn) : '${_bnNum(i + 1)}  ${enDigits(engine.currentDeck[i].labelBn)}',
            style: zlText(12, weight: FontWeight.w800, color: ZlColors.green),
          ),
        ),
      ),
    );
  }
}

class _PlayBoard extends StatefulWidget {
  final DutySlipEngine engine;
  final void Function(String id, Offset global) onPlan;
  const _PlayBoard({required this.engine, required this.onPlan});

  @override
  State<_PlayBoard> createState() => _PlayBoardState();
}

class _PlayBoardState extends State<_PlayBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _deal;
  var _step = -1;
  var _stamp = -1;

  @override
  void initState() {
    super.initState();
    _deal = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _kick();
  }

  @override
  void didUpdateWidget(covariant _PlayBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _kick();
  }

  void _kick() {
    final next = widget.engine.planNext;
    final stamp = widget.engine.poolStamp;
    if (next == _step && stamp == _stamp) return;
    _step = next;
    _stamp = stamp;
    _deal.forward(from: 0);
  }

  @override
  void dispose() {
    _deal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final n = e.easyChoices.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          _PickedStrip(engine: e),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2740),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ZlColors.amber.withValues(alpha: 0.55)),
            ),
            child: Text(
              e.planNext == 0 ? 'শুরুর ধাপ কোনটি?' : 'পরের ধাপ কোনটি?',
              textAlign: TextAlign.center,
              style: zlText(20, weight: FontWeight.w900, color: ZlColors.amber),
            ),
          ),
          _DealDeck(animation: _deal),
          Expanded(
            child: ListView.separated(
              clipBehavior: Clip.none,
              itemCount: n,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = e.easyChoices[i];
                return _DealCard(
                  animation: _deal,
                  index: i,
                  count: n,
                  child: _ChoiceCard(
                    item: p,
                    hot: e.streak >= 3,
                    onTapDown: (d) => widget.onPlan(p.id, d.globalPosition),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayCard extends StatelessWidget {
  final DutySlipEngine engine;
  final DsStep step;
  final List<DsOption> pool;
  final int kitIndex;
  final bool hintOn;
  final bool hintOpen;
  final String? hint;
  final int ynKey;
  final VoidCallback onHint;
  final void Function(String id, Offset global) onSingle;
  final void Function(bool take, Offset global) onYn;

  const _PlayCard({
    required this.engine,
    required this.step,
    required this.pool,
    required this.kitIndex,
    required this.hintOn,
    required this.hintOpen,
    required this.hint,
    required this.ynKey,
    required this.onHint,
    required this.onSingle,
    required this.onYn,
  });

  @override
  Widget build(BuildContext context) {
    if (step.kind == DsKind.kit && kitIndex < pool.length) {
      final o = pool[kitIndex];
      final ppe = step.id == 'ppe';
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            Text('${kitIndex + 1} / ${pool.length}', style: zlText(13, weight: FontWeight.w800, color: ZlColors.soft)),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                child: _YnCard(
                  key: ValueKey('$ynKey-${o.id}'),
                  option: o,
                  ask: ppe ? 'এই কবচ লাগবে?' : 'এই টুল ভ্যানে তুলবেন?',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'না',
                    tone: _BtnTone.bad,
                    onTapDown: (d) => onYn(false, d.globalPosition),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    label: 'হ্যাঁ',
                    tone: _BtnTone.good,
                    onTapDown: (d) => onYn(true, d.globalPosition),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text('${engine.stepIndex + 1} / ${engine.totalSteps}', style: zlText(13, weight: FontWeight.w700, color: ZlColors.soft)),
              const Spacer(),
              if (hintOn)
                TextButton(
                  onPressed: onHint,
                  child: Text('হিন্ট', style: zlText(13, weight: FontWeight.w800, color: ZlColors.amber)),
                ),
            ],
          ),
          if (step.scene.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DsBoxDecode.asset(
                context,
                step.scene,
                w: MediaQuery.sizeOf(context).width,
                h: 150,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(engine.fill(step.promptBn), textAlign: TextAlign.center, style: zlText(20, weight: FontWeight.w900, height: 1.3)),
          if (hintOpen && hint != null) ...[
            const SizedBox(height: 8),
            Text(hint!, textAlign: TextAlign.center, style: zlText(14, weight: FontWeight.w700, color: ZlColors.amber, height: 1.3)),
          ],
          const SizedBox(height: 14),
          for (final o in pool)
            _LineOpt(
              label: engine.optionLabel(o),
              image: o.image,
              onTapDown: (d) => onSingle(o.id, d.globalPosition),
            ),
        ],
      ),
    );
  }
}

class _YnCard extends StatelessWidget {
  final DsOption option;
  final String ask;
  const _YnCard({super.key, required this.option, required this.ask});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xE0161F32),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZlColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(ask, style: zlText(16, weight: FontWeight.w700, color: ZlColors.soft)),
          const SizedBox(height: 12),
          Expanded(
            child: option.image.isEmpty
                ? const Icon(Icons.handyman_rounded, size: 88, color: ZlColors.amber)
                : Image.asset(option.image, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.handyman_rounded, size: 88, color: ZlColors.amber)),
          ),
          const SizedBox(height: 10),
          Text(enDigits(option.labelBn), textAlign: TextAlign.center, style: zlText(22, weight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ResultBoard extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  final bool muted;
  const _ResultBoard({
    required this.engine,
    required this.onNext,
    required this.onRetry,
    this.onBack,
    required this.muted,
  });

  @override
  State<_ResultBoard> createState() => _ResultBoardState();
}

class _ResultBoardState extends State<_ResultBoard> with TickerProviderStateMixin {
  late final AnimationController _show;
  late final AnimationController _burst;
  late final AnimationController _jolt;
  final _cued = <int>{};

  bool get _ok => widget.engine.levelRank != DsLevelRank.again;

  @override
  void initState() {
    super.initState();
    _show = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..addListener(_onShow)
      ..forward();
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _jolt = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
    if (_ok) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      _jolt.forward();
    }
  }

  void _cue(int id, double at, String file, {double volume = 0.7}) {
    if (_cued.contains(id) || _show.value < at) return;
    _cued.add(id);
    unawaited(ZlFx.cue(file, volume: volume, muted: widget.muted));
  }

  void _onShow() {
    if (_ok) {
      _cue(0, 0.02, 'sounds/quiz_complete.ogg', volume: 0.9);
      _cue(1, 0.16, 'sounds/quiz_select.ogg', volume: 0.38);
      _cue(2, 0.40, 'sounds/quiz_right.ogg', volume: 0.72);
      _cue(3, 0.44, 'sounds/quiz_flip.ogg', volume: 0.42);
      _cue(4, 0.68, 'sounds/quiz_select.ogg', volume: 0.32);
    } else {
      _cue(0, 0.02, 'sounds/accident.ogg', volume: 0.88);
      _cue(1, 0.16, 'sounds/quiz_select.ogg', volume: 0.34);
      _cue(2, 0.44, 'sounds/quiz_flip.ogg', volume: 0.38);
      _cue(3, 0.68, 'sounds/quiz_wrong.ogg', volume: 0.72);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (slmLoopsOn(context)) {
      if (!_burst.isAnimating) _burst.repeat();
    } else {
      _burst.stop();
    }
  }

  @override
  void dispose() {
    _show.removeListener(_onShow);
    _show.dispose();
    _burst.dispose();
    _jolt.dispose();
    super.dispose();
  }

  double _span(double t, double a, double b, {Curve curve = Curves.easeOutCubic}) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final wrong = e.wrongTaps;
    final total = e.nightTotal;
    return AnimatedBuilder(
      animation: Listenable.merge([_show, _jolt]),
      builder: (_, _) {
        final t = _show.value;
        final drop = _span(t, 0.00, 0.16, curve: Curves.easeOutBack);
        final scoreT = _span(t, 0.16, 0.40);
        final timeIn = _span(t, 0.40, 0.48);
        final timeT = _span(t, 0.44, 0.64);
        final missIn = _span(t, 0.64, 0.72);
        final missT = _span(t, 0.68, 0.82);
        final capIn = _span(t, 0.84, 0.94);
        final btnIn = _span(t, 0.90, 1.00);
        final shownScore = (total * scoreT).round();
        final shownSec = (e.playSeconds * timeT).round();
        final shownWrong = (wrong * missT).round();
        final jolt = _ok ? 0.0 : math.sin(_jolt.value * math.pi * 6) * (1 - _jolt.value) * 10;
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _CelebratePainter(time: _burst, reveal: drop, ok: _ok),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
              child: Transform.translate(
                offset: Offset(jolt, 0),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Opacity(
                      opacity: drop.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - drop.clamp(0.0, 1.0)) * 42),
                        child: Transform.scale(
                          scale: 0.78 + 0.22 * drop.clamp(0.0, 1.2),
                          child: _ScoreBadge(score: shownScore, ok: _ok, shine: _burst),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: timeIn,
                            child: _ResultStat(
                              label: 'সময়',
                              value: e.formatClock(shownSec),
                              color: const Color(0xFFF6E7B0),
                              note: timeT >= 1 ? _bestNote(e) : null,
                            ),
                          ),
                        ),
                        Container(width: 1, height: 72, color: Color.fromRGBO(201, 162, 39, 0.2 * missIn.clamp(0.0, 1.0))),
                        Expanded(
                          child: Opacity(
                            opacity: missIn,
                            child: _ResultStat(
                              label: 'ভুল',
                              value: _bnNum(shownWrong),
                              color: shownWrong == 0 ? ZlColors.green : const Color(0xFFE85D5D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: capIn,
                      child: Text(
                        'প্রতিটি ভুল আসলে একবার মৃত্যুর সম্ভাবনা!',
                        textAlign: TextAlign.center,
                        style: zlText(15, weight: FontWeight.w700, height: 1.45, color: const Color(0xFFC4B48A)),
                      ),
                    ),
                    const Spacer(flex: 3),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            if (widget.onBack != null)
              Positioned(
                top: 10,
                left: 12,
                child: Opacity(
                  opacity: btnIn,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onBack!();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xCC091422),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x44FBBF24)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFDE68A), size: 20),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: _FloatArrow(
                  reveal: btnIn,
                  onTap: _ok ? widget.onNext : widget.onRetry,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _bestNote(DutySlipEngine e) {
    final best = e.bestDarunSec[e.levelIndex];
    if (best == null) return null;
    if (best == e.playSeconds) return 'সেরা';
    return 'সেরা ${e.formatClock(best)}';
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? note;
  const _ResultStat({required this.label, required this.value, required this.color, this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: zlText(13, weight: FontWeight.w700, height: 1.2, color: const Color(0xFFB7A57A)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: zlText(36, weight: FontWeight.w900, height: 1.1, color: color),
            ),
          ),
        ),
        SizedBox(
          height: 18,
          child: note == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.center,
                  child: Text(
                    note!,
                    textAlign: TextAlign.center,
                    style: zlText(11, weight: FontWeight.w700, height: 1, color: const Color(0xFFC9A227)),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final bool ok;
  final Animation<double> shine;
  const _ScoreBadge({required this.score, required this.ok, required this.shine});

  @override
  Widget build(BuildContext context) {
    const w = 128.0;
    const h = 148.0;
    final r = w * 0.42;
    final cy = h * 0.58;
    final well = r * 1.08;
    final digits = '$score'.length;
    final size = digits <= 2 ? 36.0 : digits == 3 ? 30.0 : 24.0;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _MedalPainter(ok: ok, shine: shine), size: const Size(w, h)),
          ),
          Positioned(
            left: (w - well) / 2,
            top: cy - well / 2,
            width: well,
            height: well,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$score',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: zlText(size, weight: FontWeight.w900, height: 1, color: const Color(0xFF1A1206)).copyWith(
                    letterSpacing: digits > 2 ? -0.8 : 0,
                    shadows: const [
                      Shadow(offset: Offset(0, 1), color: Color(0x66FFFFFF), blurRadius: 0),
                      Shadow(offset: Offset(0, -0.8), color: Color(0x55000000), blurRadius: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  final bool ok;
  /// Repaints from the animation directly; no widget rebuild per frame.
  final Animation<double> shine;
  _MedalPainter({required this.ok, required this.shine}) : super(repaint: shine);

  Path _octa(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final c = Offset(cx, size.height * 0.58);
    final r = size.width * 0.42;
    final metal = ok
        ? const [Color(0xFFFFF6D4), Color(0xFFE0B13A), Color(0xFF7A4E10)]
        : const [Color(0xFFD8C8B0), Color(0xFF8A6A48), Color(0xFF3E2814)];
    final rim = ok ? const Color(0xFFF8E7B0) : const Color(0xFFC4A878);
    final dark = ok ? const Color(0xFF4A300C) : const Color(0xFF2A1A0C);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.92), width: r * 1.7, height: 12),
      Paint()..color = const Color(0x66000000),
    );

    final ring = Offset(cx, 16);
    canvas.drawCircle(ring, 9.2, Paint()..color = dark);
    canvas.drawCircle(
      ring,
      8.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: metal,
        ).createShader(Rect.fromCircle(center: ring, radius: 10)),
    );
    canvas.drawCircle(
      ring,
      8.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..color = rim.withValues(alpha: 0.85),
    );
    canvas.drawLine(
      Offset(cx, 24.5),
      Offset(cx, c.dy - r + 4),
      Paint()
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: metal).createShader(Rect.fromLTWH(cx - 2, 24, 4, 28)),
    );

    canvas.save();
    canvas.translate(0, 3.2);
    canvas.drawPath(_octa(c, r + 1.4), Paint()..color = dark);
    canvas.restore();

    final face = _octa(c, r);
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: metal,
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = rim,
    );
    canvas.drawPath(
      _octa(c, r * 0.82),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [metal[1], metal[2], metal[0]],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.82)),
    );
    canvas.drawCircle(
      c,
      r * 0.58,
      Paint()
        ..shader = RadialGradient(
          colors: [metal[0].withValues(alpha: 0.55), metal[2].withValues(alpha: 0.55)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.58)),
    );
    canvas.drawCircle(
      c,
      r * 0.58,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = dark.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      c,
      r * 0.48,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = rim.withValues(alpha: 0.45),
    );

    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final p = c + Offset(math.cos(a) * r * 0.9, math.sin(a) * r * 0.9);
      canvas.drawCircle(
        p,
        3.1,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [rim, metal[1], dark],
          ).createShader(Rect.fromCircle(center: p, radius: 3.1)),
      );
      canvas.drawCircle(p, 1.05, Paint()..color = const Color(0x66FFFFFF));
    }

    final gloss = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(c.dx - r * 0.18 + math.sin(shine.value * math.pi * 2) * 6, c.dy - r * 0.28),
        width: r * 0.9,
        height: r * 0.42,
      ));
    canvas.save();
    canvas.clipPath(face);
    canvas.drawPath(gloss, Paint()..color = const Color(0x33FFFFFF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) => old.ok != ok || old.shine != shine;
}

class _CelebratePainter extends CustomPainter {
  /// Repaints from the animation directly; no widget rebuild per frame.
  final Animation<double> anim;
  final double reveal;
  final bool ok;
  _CelebratePainter({required Animation<double> time, required this.reveal, required this.ok})
      : anim = time,
        super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) {
    final time = anim.value;
    final c = Offset(size.width / 2, size.height * 0.22);
    final a = (reveal * 0.9).clamp(0.0, 1.0);
    if (ok) {
      canvas.drawCircle(c, 34 + reveal * 110, Paint()..color = Color.fromRGBO(251, 191, 36, 0.12 * a));
      canvas.drawCircle(c, 14 + reveal * 48, Paint()..color = Color.fromRGBO(246, 231, 176, 0.18 * a));
      for (var i = 0; i < 22; i++) {
        final ang = i * math.pi / 11 + time * math.pi * 2;
        final dist = 40 + 88 * ((math.sin(time * math.pi * 2 + i) + 1) / 2);
        final p = c + Offset(math.cos(ang) * dist, math.sin(ang) * dist * 0.86);
        canvas.drawCircle(
          p,
          2.0 + (i.isEven ? 1.4 : 0),
          Paint()..color = Color.fromRGBO(255, 214, 120, 0.58 * a),
        );
      }
      return;
    }
    canvas.drawCircle(c, 40 + reveal * 90, Paint()..color = Color.fromRGBO(180, 40, 28, 0.16 * a));
    canvas.drawCircle(c, 16 + reveal * 36, Paint()..color = Color.fromRGBO(80, 16, 10, 0.22 * a));
    for (var i = 0; i < 16; i++) {
      final fall = (time * 0.85 + i * 0.07) % 1.0;
      final x = size.width * (0.18 + (i * 0.047) % 0.64);
      final y = size.height * (0.06 + fall * 0.52);
      canvas.drawCircle(
        Offset(x, y),
        1.6 + (i.isEven ? 1.1 : 0),
        Paint()..color = Color.fromRGBO(220, 70, 48, (0.55 - fall * 0.45) * a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebratePainter old) => old.anim != anim || old.reveal != reveal || old.ok != ok;
}

enum _BtnTone { primary, good, bad, ghost }

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final _BtnTone tone;

  const _ActionBtn({
    required this.label,
    this.onTap,
    this.onTapDown,
    this.tone = _BtnTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color border, Color text) = switch (tone) {
      _BtnTone.primary => (ZlColors.amber, ZlColors.amber, const Color(0xFF111827)),
      _BtnTone.good => (ZlColors.green.withValues(alpha: 0.18), ZlColors.green, ZlColors.green),
      _BtnTone.bad => (ZlColors.red.withValues(alpha: 0.16), ZlColors.red, ZlColors.red),
      _BtnTone.ghost => (Colors.transparent, ZlColors.line, ZlColors.soft),
    };
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onTapDown: onTapDown,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.3),
          ),
          child: Text(label, textAlign: TextAlign.center, style: zlText(16, weight: FontWeight.w800, color: text)),
        ),
      ),
    );
  }
}

class _ChipPick extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipPick({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B2740),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ZlColors.amber.withValues(alpha: 0.5)),
          ),
          child: Text(label, style: zlText(13, weight: FontWeight.w800, color: ZlColors.amber)),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final DsPlanItem item;
  final bool hot;
  final GestureTapDownCallback onTapDown;
  const _ChoiceCard({required this.item, required this.onTapDown, this.hot = false});

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      onTapDown: onTapDown,
      child: Text(
        enDigits(item.labelBn),
        textAlign: TextAlign.center,
        style: zlText(
          18,
          weight: FontWeight.w800,
          height: 1.25,
          color: hot ? const Color(0xFFB45309) : const Color(0xFF1A140C),
        ),
      ),
    );
  }
}

class _LineOpt extends StatelessWidget {
  final String label;
  final String image;
  final GestureTapDownCallback onTapDown;
  const _LineOpt({required this.label, required this.image, required this.onTapDown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xE01B2740),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: onTapDown,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZlColors.line),
            ),
            child: Row(
              children: [
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: DsBoxDecode.asset(
                      context,
                      image,
                      w: 58,
                      h: 58,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.circle_outlined, color: ZlColors.soft),
                    ),
                  )
                else
                  const Icon(Icons.circle_outlined, color: ZlColors.soft, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: zlText(16, weight: FontWeight.w800, height: 1.25))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallBurst extends StatelessWidget {
  final DutySlipEngine engine;
  final DsCall call;
  final bool open;
  final VoidCallback onOpen;
  final void Function(String id, Offset global) onReply;

  const _CallBurst({
    required this.engine,
    required this.call,
    required this.open,
    required this.onOpen,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(1.05, 0), end: Offset.zero),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, offset, child) => FractionalTranslation(translation: offset, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0xF02C1A12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ZlColors.orange, width: 1.4),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DsBoxDecode.asset(
                  context,
                  call.portrait,
                  w: 120,
                  h: 120,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.person, size: 72, color: ZlColors.amber),
                ),
              ),
              const SizedBox(height: 10),
              Text(engine.fill(call.whoBn), style: zlText(20, weight: FontWeight.w900, color: ZlColors.amber)),
              const SizedBox(height: 8),
              Text(engine.fill(call.lineBn), textAlign: TextAlign.center, style: zlText(17, weight: FontWeight.w800, height: 1.35)),
              const Spacer(),
              if (!open)
                _ActionBtn(label: 'জবাব দিন', onTap: onOpen)
              else
                Column(
                  children: [
                    for (final r in call.replies)
                      _LineOpt(label: engine.fill(r.labelBn), image: '', onTapDown: (d) => onReply(r.id, d.globalPosition)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  final DutySlipEngine engine;
  final VoidCallback onClose;
  const _Report({required this.engine, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final e = engine;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xF0131C2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ZlColors.amber.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Text(e.gradeBn(), style: zlText(20, weight: FontWeight.w900, color: ZlColors.amber)),
          const SizedBox(height: 6),
          Text('${e.feeder} · ${e.site.nameBn}', style: zlText(14, color: ZlColors.soft)),
          const SizedBox(height: 12),
          Text(e.clockLabel, style: zlText(34, weight: FontWeight.w900, color: ZlColors.amber)),
          Text('স্কোর ${e.quality}', style: zlText(16, weight: FontWeight.w800)),
          if (e.lethalReason != null) ...[
            const SizedBox(height: 8),
            Text(e.lethalReason!, textAlign: TextAlign.center, style: zlText(14, color: ZlColors.red)),
          ],
          const SizedBox(height: 16),
          _ActionBtn(label: 'শেষ', onTap: onClose),
        ],
      ),
    );
  }
}
