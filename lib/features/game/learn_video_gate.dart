import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'learn_board_models.dart';
import 'learn_board_runner.dart';
import 'scene_kit.dart';

/// Immersive Learn entry: guide asks for careful listening → YouTube explainer
/// → force portrait (if they rotated for the video) → guide says play carefully
/// → existing [LearnBoardRunnerPage].
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
  });

  final String rungId;
  final String lessonId;
  final int ladderIndex;
  final LearnBoardPack pack;
  final String youtubeId;
  final bool muted;

  @override
  ConsumerState<LearnVideoGatePage> createState() => _LearnVideoGatePageState();
}

enum _GatePhase { listenGuide, video, playGuide, board }

class _LearnVideoGatePageState extends ConsumerState<LearnVideoGatePage> {
  var _phase = _GatePhase.listenGuide;
  YoutubePlayerController? _yt;
  StreamSubscription<YoutubePlayerValue>? _ytSub;
  var _sawLandscape = false;
  var _videoDone = false;
  var _loadFailed = false;

  static const _listenLineBn = 'এই ভিডিও মন দিয়ে শুনুন—তারপর এগোব।';
  static const _playLineBn = 'এবার সাবধানে খেলুন। ভুল মানে বিপদ।';

  @override
  void dispose() {
    unawaited(_ytSub?.cancel() ?? Future<void>.value());
    final yt = _yt;
    _yt = null;
    if (yt != null) unawaited(yt.close());
    unawaited(_restoreOrientations());
    unawaited(MascotSpeechLibrary.stop());
    super.dispose();
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

  void _onListenDone() {
    if (!mounted || _phase != _GatePhase.listenGuide) return;
    setState(() => _phase = _GatePhase.video);
    unawaited(_startVideo());
  }

  Future<void> _startVideo() async {
    await _allowVideoOrientations();
    if (!mounted) return;
    try {
      final c = YoutubePlayerController.fromVideoId(
        videoId: widget.youtubeId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          mute: false,
          strictRelatedVideos: true,
        ),
      );
      _yt = c;
      _ytSub = c.listen((value) {
        if (!mounted || _videoDone) return;
        if (value.playerState == PlayerState.ended) {
          unawaited(_finishVideo());
        }
      });
      if (mounted) setState(() => _loadFailed = false);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _finishVideo() async {
    if (_videoDone) return;
    _videoDone = true;
    await _ytSub?.cancel();
    _ytSub = null;
    try {
      await _yt?.pauseVideo();
    } catch (_) {}
    // Always return the Learn board to portrait; especially after landscape watch.
    await _forcePortrait();
    if (!mounted) return;
    setState(() => _phase = _GatePhase.playGuide);
  }

  void _onPlayGuideDone() {
    if (!mounted || _phase != _GatePhase.playGuide) return;
    final yt = _yt;
    _yt = null;
    if (yt != null) unawaited(yt.close());
    setState(() => _phase = _GatePhase.board);
  }

  void _noteOrientation(Orientation o) {
    if (_phase == _GatePhase.video && o == Orientation.landscape) {
      _sawLandscape = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _noteOrientation(MediaQuery.orientationOf(context));

    if (_phase == _GatePhase.board) {
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
        // From the video: leave Learn without clearing.
        unawaited(_forcePortrait());
        if (mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070D1A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_phase == _GatePhase.video) _buildVideo(),
            if (_phase == _GatePhase.listenGuide)
              GuideIntro(
                line: _listenLineBn,
                muted: widget.muted,
                alarm: 'sounds/learn/rush_in.wav',
                onDone: _onListenDone,
              ),
            if (_phase == _GatePhase.playGuide)
              GuideIntro(
                line: _playLineBn,
                muted: widget.muted,
                alarm: null,
                onDone: _onPlayGuideDone,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final c = _yt;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
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
          Expanded(
            child: Center(
              child: _loadFailed || c == null
                  ? _OfflineVideo(
                      onRetry: () {
                        setState(() {
                          _loadFailed = false;
                          _videoDone = false;
                        });
                        unawaited(_startVideo());
                      },
                      onSkip: () => unawaited(_finishVideo()),
                    )
                  : YoutubePlayer(
                      controller: c,
                      aspectRatio: 16 / 9,
                      backgroundColor: const Color(0xFF070D1A),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Text(
                  _sawLandscape
                      ? 'ভিডিও শেষ হলে ফোন সোজা হবে — তারপর খেলা।'
                      : 'মন দিয়ে দেখুন। শেষে এগোবেন।',
                  textAlign: TextAlign.center,
                  style: bangla(fontSize: 13, fontWeight: FontWeight.w600, color: SlmColors.ivory.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.45, muted: false));
                      HapticFeedback.mediumImpact();
                      unawaited(_finishVideo());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: SlmColors.gold300,
                      foregroundColor: const Color(0xFF1A1008),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('এগিয়ে যান', style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1A1008))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineVideo extends StatelessWidget {
  const _OfflineVideo({required this.onRetry, required this.onSkip});
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ভিডিও এখন লোড হয়নি। নেট চেক করে আবার চেষ্টা করুন।',
            textAlign: TextAlign.center,
            style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text('আবার চেষ্টা', style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text('এগিয়ে যান', style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.gold300)),
          ),
        ],
      ),
    );
  }
}
