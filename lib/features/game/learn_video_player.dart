import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// What the Learn video gate sees of a player.
enum LearnVideoStatus { loading, ready, playing, paused, buffering, ended, error }

/// The few things [LearnVideoGatePage] needs from a video player. The app uses
/// [YoutubeLearnVideoPlayer]; tests use a fake (no webview).
abstract class LearnVideoPlayer {
  Stream<LearnVideoStatus> get statusStream;
  LearnVideoStatus get status;
  Future<double> positionSeconds();

  /// 0 until the player knows it.
  Future<double> durationSeconds();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(double seconds);

  /// The video surface. When [locked] (first watch) the player's own
  /// controls and seek gestures are gone and [lockedControls] is laid over
  /// the video instead; it gets the player's fullscreen button, if any.
  Widget view({
    required bool locked,
    required Widget Function(BuildContext context, Widget? fullscreenButton) lockedControls,
  });

  Future<void> close();
}

typedef LearnVideoPlayerFactory = LearnVideoPlayer Function(String videoId, {required bool firstWatch});

/// YouTube (youtube_player_flutter) behind [LearnVideoPlayer].
class YoutubeLearnVideoPlayer implements LearnVideoPlayer {
  YoutubeLearnVideoPlayer(String videoId, {required bool firstWatch})
      : _c = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: YoutubePlayerParams(
            showFullscreenButton: true,
            mute: false,
            strictRelatedVideos: true,
            // First watch: no YouTube controls, no keyboard, no taps into
            // the iframe — only our play/pause and fullscreen.
            showControls: !firstWatch,
            enableKeyboard: false,
            pointerEvents: firstWatch ? PointerEvents.none : PointerEvents.initial,
          ),
        ) {
    _sub = _c.listen(_onValue);
  }

  static LearnVideoPlayer create(String videoId, {required bool firstWatch}) =>
      YoutubeLearnVideoPlayer(videoId, firstWatch: firstWatch);

  final YoutubePlayerController _c;
  StreamSubscription<YoutubePlayerValue>? _sub;
  final _statusCtl = StreamController<LearnVideoStatus>.broadcast();
  var _status = LearnVideoStatus.loading;

  void _onValue(YoutubePlayerValue v) {
    final s = v.hasError
        ? LearnVideoStatus.error
        : switch (v.playerState) {
            PlayerState.unknown => LearnVideoStatus.loading,
            PlayerState.unStarted || PlayerState.cued => LearnVideoStatus.ready,
            PlayerState.playing => LearnVideoStatus.playing,
            PlayerState.paused => LearnVideoStatus.paused,
            PlayerState.buffering => LearnVideoStatus.buffering,
            PlayerState.ended => LearnVideoStatus.ended,
          };
    if (s == _status || _statusCtl.isClosed) return;
    _status = s;
    _statusCtl.add(s);
  }

  @override
  Stream<LearnVideoStatus> get statusStream => _statusCtl.stream;

  @override
  LearnVideoStatus get status => _status;

  @override
  Future<double> positionSeconds() => _c.currentTime;

  @override
  Future<double> durationSeconds() async {
    final known = _c.metadata.duration;
    if (known > Duration.zero) return known.inMilliseconds / 1000;
    return _c.duration;
  }

  @override
  Future<void> play() => _c.playVideo();

  @override
  Future<void> pause() => _c.pauseVideo();

  @override
  Future<void> seekTo(double seconds) => _c.seekTo(seconds: seconds, allowSeekAhead: true);

  @override
  Widget view({
    required bool locked,
    required Widget Function(BuildContext context, Widget? fullscreenButton) lockedControls,
  }) {
    return YoutubePlayer(
      controller: _c,
      aspectRatio: 16 / 9,
      backgroundColor: const Color(0xFF070D1A),
      // A builder replaces the package's controls overlay (seek bar and
      // horizontal-drag seek) with ours.
      builder: locked
          ? (ctx, player, c) => Stack(
                fit: StackFit.expand,
                children: [player, lockedControls(ctx, FullscreenButton(controller: c))],
              )
          : null,
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    await _statusCtl.close();
    await _c.close();
  }
}

/// First-watch accounting: seconds really watched, and skip detection.
///
/// Feed it the player position about every 500 ms. Forward progress up to
/// [maxRate] × the wall time since the last sample (plus a small [slack] for
/// sampling jitter) counts while playing. A bigger forward jump past what
/// was already watched is a skip: [sample] returns where to seek back to.
/// Backward seeks are fine. Paused / buffering samples never count.
class FirstWatchTracker {
  FirstWatchTracker({this.maxRate = 1.5, this.slack = 0.35, this.needFraction = 0.95, this.endWindow = 2});

  final double maxRate;
  final double slack;

  /// Share of the duration that must really be watched.
  final double needFraction;

  /// Seconds before the end that count as "reached the end".
  final double endWindow;

  /// Seconds really watched.
  double watched = 0;

  /// Last accepted position (seconds).
  double position = 0;

  /// Furthest accepted position (seconds).
  double furthest = 0;

  /// One sample at [pos] seconds, [elapsed] wall seconds after the previous
  /// one. [counting] only while the video is playing. Returns the position to
  /// seek back to when this was a skip, else null.
  double? sample(double pos, double elapsed, {required bool counting}) {
    final delta = pos - position;
    if (delta <= 0) {
      position = math.max(0, pos);
      return null;
    }
    final allowed = (counting ? math.max(0.0, elapsed) * maxRate : 0) + slack;
    if (delta <= allowed) {
      if (counting) watched += delta;
      position = pos;
      furthest = math.max(furthest, pos);
      return null;
    }
    // Back to ground already watched after a rewind: no skip, no credit.
    if (pos <= furthest + slack) {
      position = pos;
      return null;
    }
    return position;
  }

  double fraction(double duration) => duration <= 0 ? 0 : (watched / duration).clamp(0.0, 1.0);

  bool atEnd(double pos, double duration, {required bool ended}) =>
      ended || (duration > 0 && pos >= duration - endWindow);

  /// Watched enough and at the end.
  bool complete(double duration, {required bool atEnd}) =>
      duration > 0 && atEnd && watched >= needFraction * duration;

  /// At the end but short of [needFraction]: where to restart so the
  /// missing seconds get watched.
  double replayFrom(double duration) {
    final missing = needFraction * duration - watched;
    return math.max(0, duration - missing - endWindow - 1);
  }
}
