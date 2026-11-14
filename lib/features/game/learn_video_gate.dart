import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'game_save.dart';
import 'learn_board_models.dart';
import 'learn_board_runner.dart';
import 'learn_video_player.dart';
import 'mistake_kit.dart' show openLessonPoint;
import 'scene_kit.dart';

/// Immersive Learn entry: guide asks for careful listening → YouTube explainer
/// → force portrait (if they rotated for the video) → guide says play carefully
/// → existing [LearnBoardRunnerPage].
///
/// Owner rule: the FIRST time through a lesson the whole video must be watched
/// (no seek bar, no skip; forward jumps are pulled back) before the board
/// opens. Once [GameSave.videosWatched] has the lesson, later visits get the
/// normal controls and a skip button.
///
/// Only opened when [LearnExplainerVideos] has an id for this lesson.
class LearnVideoGatePage extends ConsumerStatefulWidget {
  const LearnVideoGatePage({
    super.key,
    required this.rungId,
    required this.lessonId,
    required this.ladderIndex,
    required this.pack,
    required this.youtubeId,
    this.muted = false,
    this.playerFactory,
    this.boardBuilder,
    this.guideBuilder,
    this.onReadLesson,
    this.wallClock,
    this.loadTimeout = const Duration(seconds: 15),
  });

  final String rungId;
  final String lessonId;
  final int ladderIndex;
  final LearnBoardPack pack;
  final String youtubeId;
  final bool muted;

  /// Tests: a fake player instead of YouTube.
  @visibleForTesting
  final LearnVideoPlayerFactory? playerFactory;

  /// Tests: stands in for [LearnBoardRunnerPage].
  @visibleForTesting
  final WidgetBuilder? boardBuilder;

  /// Tests: stands in for [GuideIntro] (call `onDone` to move on).
  @visibleForTesting
  final Widget Function(String line, VoidCallback onDone)? guideBuilder;

  /// Opens the lesson reader; defaults to [openLessonPoint].
  @visibleForTesting
  final Future<void> Function(BuildContext context)? onReadLesson;

  /// Tests: monotonic wall time for the watch-time check.
  @visibleForTesting
  final Duration Function()? wallClock;

  /// No player answer by then = could not load (offline).
  final Duration loadTimeout;

  @override
  ConsumerState<LearnVideoGatePage> createState() => _LearnVideoGatePageState();
}

enum _GatePhase { listenGuide, video, playGuide, board }

class _LearnVideoGatePageState extends ConsumerState<LearnVideoGatePage> {
  var _phase = _GatePhase.listenGuide;
  LearnVideoPlayer? _player;
  StreamSubscription<LearnVideoStatus>? _statusSub;
  var _sawLandscape = false;
  var _videoDone = false;
  var _loadFailed = false;

  /// Fixed when the page opens: true until this lesson's video was watched once.
  late final bool _firstWatch;

  final _status = ValueNotifier<LearnVideoStatus>(LearnVideoStatus.loading);
  final _watchedFraction = ValueNotifier<double>(0);
  var _tracker = FirstWatchTracker();
  Timer? _sampleTimer;
  Timer? _loadTimer;
  Future<void> _sampling = Future<void>.value();
  var _sampleBusy = false;
  var _lastSampleAt = Duration.zero;
  double _duration = 0;
  Duration? _lastToastAt;
  final _clock = Stopwatch()..start();
  late final AppLifecycleListener _life;

  static const _listenLineBn = 'এই ভিডিও মন দিয়ে শুনুন—তারপর এগোব।';
  static const _playLineBn = 'এবার সাবধানে খেলুন। ভুল মানে বিপদ।';
  static const _mustWatchBn = 'প্রথমবার পুরো ভিডিওটি দেখতে হবে';
  static const _needNetBn = 'ভিডিওটি দেখতে ইন্টারনেট দরকার';

  @override
  void initState() {
    super.initState();
    _firstWatch = !ref.read(gameSaveProvider).videosWatched.contains(widget.lessonId);
    // Backgrounding pauses the video; watch time so far stays for this visit.
    _life = AppLifecycleListener(onHide: _onAppHidden);
  }

  @override
  void dispose() {
    _life.dispose();
    _stopSampling();
    _loadTimer?.cancel();
    unawaited(_statusSub?.cancel() ?? Future<void>.value());
    _closePlayer();
    _status.dispose();
    _watchedFraction.dispose();
    unawaited(_restoreOrientations());
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
  }

  Duration _now() => widget.wallClock?.call() ?? _clock.elapsed;

  void _closePlayer() {
    final p = _player;
    _player = null;
    if (p != null) unawaited(p.close().catchError((_) {}));
  }

  Future<void> _allowVideoOrientations() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _restoreOrientations() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  void _onAppHidden() {
    if (_phase != _GatePhase.video || _videoDone) return;
    final p = _player;
    if (p != null) unawaited(p.pause().catchError((_) {}));
  }

  void _onListenDone() {
    if (!mounted || _phase != _GatePhase.listenGuide) return;
    setState(() => _phase = _GatePhase.video);
    unawaited(_startVideo());
  }

  Future<void> _startVideo() async {
    await _allowVideoOrientations();
    if (!mounted || _videoDone) return;
    // Each attempt counts from zero (leaving mid-video restarts the count).
    _tracker = FirstWatchTracker();
    _watchedFraction.value = 0;
    _duration = 0;
    _status.value = LearnVideoStatus.loading;
    try {
      final p = (widget.playerFactory ?? YoutubeLearnVideoPlayer.create)(widget.youtubeId, firstWatch: _firstWatch);
      _player = p;
      _statusSub = p.statusStream.listen(_onStatus);
      _loadTimer?.cancel();
      _loadTimer = Timer(widget.loadTimeout, () {
        if (_status.value == LearnVideoStatus.loading) _onLoadFailed();
      });
      setState(() => _loadFailed = false);
      if (p.status != LearnVideoStatus.loading) _onStatus(p.status);
    } catch (_) {
      _onLoadFailed();
    }
  }

  void _onStatus(LearnVideoStatus s) {
    if (!mounted || _videoDone) return;
    final was = _status.value;
    _status.value = s;
    if (s == LearnVideoStatus.error) {
      _onLoadFailed();
      return;
    }
    if (s != LearnVideoStatus.loading) _loadTimer?.cancel();
    if (!_firstWatch) {
      if (s == LearnVideoStatus.ended) unawaited(_finishVideo());
      return;
    }
    if (s == LearnVideoStatus.playing) {
      _lastSampleAt = _now();
      _sampleTimer ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!_sampleBusy) _queueSample();
      });
      return;
    }
    // Not playing: no clock (idle draws nothing). Close the playing stretch
    // with one last counted sample; paused / buffering time never counts.
    _stopSampling();
    _queueSample(counting: was == LearnVideoStatus.playing || s == LearnVideoStatus.ended);
  }

  void _stopSampling() {
    _sampleTimer?.cancel();
    _sampleTimer = null;
  }

  void _queueSample({bool counting = true}) {
    _sampling = _sampling.then((_) => _sample(counting: counting)).catchError((_) {});
  }

  Future<void> _sample({required bool counting}) async {
    final p = _player;
    if (p == null || _videoDone || !mounted) return;
    _sampleBusy = true;
    try {
      final pos = await p.positionSeconds();
      if (_duration <= 0) _duration = await p.durationSeconds();
      if (!mounted || _videoDone || _player != p) return;
      final now = _now();
      final elapsed = (now - _lastSampleAt).inMicroseconds / 1e6;
      _lastSampleAt = now;
      final ended = _status.value == LearnVideoStatus.ended;
      final back = _tracker.sample(pos, elapsed, counting: counting);
      if (back != null) {
        // A skip: back to the last watched second.
        await p.seekTo(back);
        if (ended) await p.play();
        _toast(_mustWatchBn);
        return;
      }
      _watchedFraction.value = _tracker.fraction(_duration);
      final atEnd = _tracker.atEnd(pos, _duration, ended: ended);
      if (_tracker.complete(_duration, atEnd: atEnd)) {
        await _finishVideo(markWatched: true);
      } else if (ended && _duration > 0) {
        // Reached the end short of 95 %: replay the missing part.
        await p.seekTo(_tracker.replayFrom(_duration));
        await p.play();
        _toast(_mustWatchBn);
      }
    } finally {
      _sampleBusy = false;
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    final now = _now();
    final last = _lastToastAt;
    if (last != null && now - last < const Duration(seconds: 3)) return;
    _lastToastAt = now;
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SlmColors.navy900,
        duration: const Duration(seconds: 2),
        content: Text(text, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory)),
      ),
    );
  }

  void _onLoadFailed() {
    if (!mounted || _videoDone) return;
    _stopSampling();
    _loadTimer?.cancel();
    unawaited(_statusSub?.cancel() ?? Future<void>.value());
    _statusSub = null;
    _closePlayer();
    if (!_firstWatch) {
      // Watched before: offline is no reason to hold the board.
      _skipToBoard();
      return;
    }
    // First watch: the board stays locked; never marked watched.
    setState(() => _loadFailed = true);
  }

  Future<void> _finishVideo({bool markWatched = false}) async {
    if (_videoDone) return;
    _videoDone = true;
    final save = ref.read(gameSaveProvider.notifier);
    _stopSampling();
    _loadTimer?.cancel();
    unawaited(_statusSub?.cancel() ?? Future<void>.value());
    _statusSub = null;
    try {
      await _player?.pause();
    } catch (_) {}
    if (markWatched) await save.markVideoWatched(widget.lessonId);
    // Always return the Learn board to portrait; especially after landscape watch.
    await _forcePortrait();
    if (!mounted) return;
    setState(() => _phase = _GatePhase.playGuide);
  }

  /// Later visits only: straight to the board.
  void _skipToBoard() {
    if (_phase == _GatePhase.board) return;
    _videoDone = true;
    _stopSampling();
    _loadTimer?.cancel();
    unawaited(_statusSub?.cancel() ?? Future<void>.value());
    _statusSub = null;
    _closePlayer();
    unawaited(_forcePortrait());
    if (mounted) setState(() => _phase = _GatePhase.board);
  }

  void _onPlayGuideDone() {
    if (!mounted || _phase != _GatePhase.playGuide) return;
    _closePlayer();
    setState(() => _phase = _GatePhase.board);
  }

  void _togglePlay() {
    final p = _player;
    if (p == null) return;
    HapticFeedback.selectionClick();
    if (_status.value == LearnVideoStatus.playing) {
      unawaited(p.pause().catchError((_) {}));
    } else {
      unawaited(p.play().catchError((_) {}));
    }
  }

  void _retry() {
    setState(() => _loadFailed = false);
    unawaited(_startVideo());
  }

  Future<void> _readLesson() async {
    final open = widget.onReadLesson;
    if (open != null) {
      await open(context);
      return;
    }
    await openLessonPoint(context, ref, lessonId: widget.lessonId, muted: widget.muted);
  }

  void _noteOrientation(Orientation o) {
    if (_phase == _GatePhase.video && o == Orientation.landscape) {
      _sawLandscape = true;
    }
  }

  Widget _guide(String line, String? alarm, VoidCallback onDone) {
    final b = widget.guideBuilder;
    if (b != null) return b(line, onDone);
    return GuideIntro(line: line, muted: widget.muted, alarm: alarm, onDone: onDone);
  }

  @override
  Widget build(BuildContext context) {
    _noteOrientation(MediaQuery.orientationOf(context));

    if (_phase == _GatePhase.board) {
      final b = widget.boardBuilder;
      if (b != null) return b(context);
      return LearnBoardRunnerPage(
        rungId: widget.rungId,
        lessonId: widget.lessonId,
        ladderIndex: widget.ladderIndex,
        pack: widget.pack,
        muted: widget.muted,
      );
    }

    return PopScope(
      canPop: _phase != _GatePhase.video || _videoDone,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // From the video: leave Learn without clearing (nothing marked watched).
        unawaited(_forcePortrait());
        if (mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070D1A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_phase == _GatePhase.video) _buildVideo(),
            if (_phase == _GatePhase.listenGuide) _guide(_listenLineBn, 'sounds/learn/rush_in.ogg', _onListenDone),
            if (_phase == _GatePhase.playGuide) _guide(_playLineBn, null, _onPlayGuideDone),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final p = _player;
    final Widget surface;
    if (_loadFailed) {
      surface = _OfflineFirstWatch(onRetry: _retry, onRead: () => unawaited(_readLesson()));
    } else if (p == null) {
      surface = const SizedBox.shrink();
    } else {
      surface = p.view(
        locked: _firstWatch,
        lockedControls: (ctx, fullscreen) => _LockedControls(
          status: _status,
          onTogglePlay: _togglePlay,
          fullscreenButton: fullscreen,
        ),
      );
    }
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'বন্ধ করুন',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    unawaited(_forcePortrait());
                    Navigator.of(context).pop(false);
                  },
                  icon: const Icon(Icons.close_rounded, color: SlmColors.ivory),
                ),
                Expanded(
                  child: Text(
                    enDigits(widget.pack.badgeBn),
                    textAlign: TextAlign.center,
                    style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.gold300),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(child: Center(child: surface)),
          if (_firstWatch && !_loadFailed) _WatchedBar(fraction: _watchedFraction),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                if (!_loadFailed)
                  Text(
                    _firstWatch
                        ? 'প্রথমবার পুরো ভিডিওটি দেখুন—শেষ হলে খেলা খুলবে।'
                        : _sawLandscape
                            ? 'ভিডিও শেষ হলে ফোন সোজা হবে — তারপর খেলা।'
                            : 'মন দিয়ে দেখুন। শেষে এগোবেন।',
                    textAlign: TextAlign.center,
                    style: bangla(fontSize: 13, fontWeight: FontWeight.w600, color: SlmColors.ivory.withValues(alpha: 0.75)),
                  ),
                if (!_firstWatch) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('learnVideoSkip'),
                      onPressed: () {
                        if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.45, muted: false));
                        HapticFeedback.mediumImpact();
                        _skipToBoard();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: SlmColors.gold300,
                        foregroundColor: const Color(0xFF1A1008),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('এড়িয়ে যান ›', style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1A1008))),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// First watch: our play/pause and the fullscreen button over the video —
/// no seek bar, no drag-to-seek.
class _LockedControls extends StatelessWidget {
  const _LockedControls({required this.status, required this.onTogglePlay, this.fullscreenButton});

  final ValueListenable<LearnVideoStatus> status;
  final VoidCallback onTogglePlay;
  final Widget? fullscreenButton;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            ValueListenableBuilder<LearnVideoStatus>(
              valueListenable: status,
              builder: (_, s, _) {
                final playing = s == LearnVideoStatus.playing;
                return IconButton(
                  key: const ValueKey('learnVideoPlayPause'),
                  tooltip: playing ? 'থামান' : 'চালান',
                  onPressed: onTogglePlay,
                  style: IconButton.styleFrom(backgroundColor: const Color(0x99050A16)),
                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: SlmColors.ivory),
                );
              },
            ),
            const Spacer(),
            ?fullscreenButton,
          ],
        ),
      ),
    );
  }
}

/// Thin, non-interactive bar of the time really watched (first watch).
class _WatchedBar extends StatelessWidget {
  const _WatchedBar({required this.fraction});

  final ValueListenable<double> fraction;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ValueListenableBuilder<double>(
          valueListenable: fraction,
          builder: (_, f, _) {
            final pct = (f * 100).floor();
            return Semantics(
              label: enDigits('দেখা হয়েছে $pct%'),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        key: const ValueKey('learnVideoWatched'),
                        value: f,
                        minHeight: 4,
                        backgroundColor: SlmColors.ivory.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(SlmColors.gold300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enDigits('$pct%'),
                    style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.ivory.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// First watch could not load: the board stays locked; retry or read the lesson.
class _OfflineFirstWatch extends StatelessWidget {
  const _OfflineFirstWatch({required this.onRetry, required this.onRead});
  final VoidCallback onRetry;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: SlmColors.gold300.withValues(alpha: 0.9)),
          const SizedBox(height: 12),
          Text(
            _LearnVideoGatePageState._needNetBn,
            textAlign: TextAlign.center,
            style: bangla(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'প্রথমবার পুরো ভিডিও দেখলে তবেই খেলা খুলবে।',
            textAlign: TextAlign.center,
            style: bangla(fontSize: 13, fontWeight: FontWeight.w600, color: SlmColors.ivory.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('learnVideoRetry'),
            onPressed: onRetry,
            child: Text('আবার চেষ্টা করুন', style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          TextButton.icon(
            key: const ValueKey('learnVideoRead'),
            onPressed: onRead,
            icon: const Icon(Icons.menu_book_rounded, color: SlmColors.gold300),
            label: Text('পাঠ পড়ুন', style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.gold300)),
          ),
        ],
      ),
    );
  }
}
