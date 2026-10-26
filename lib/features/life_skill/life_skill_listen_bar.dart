import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shell/shell_providers.dart';

/// Premium full-width listen strip with a wide waveform scrubber.
class LifeSkillListenBar extends StatefulWidget {
  final String audioUrl;
  final Color accent;
  final bool bn;

  const LifeSkillListenBar({
    super.key,
    required this.audioUrl,
    required this.accent,
    required this.bn,
  });

  @override
  State<LifeSkillListenBar> createState() => _LifeSkillListenBarState();
}

class _LifeSkillListenBarState extends State<LifeSkillListenBar>
    with SingleTickerProviderStateMixin {
  static const _bars = 56;

  final _player = AudioPlayer();
  late final AnimationController _pulse;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _doneSub;
  StreamSubscription<PlayerState>? _stateSub;

  late final List<double> _heights;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _loading = false;
  bool _failed = false;
  String? _loadedUrl;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.audioUrl.hashCode);
    _heights = List.generate(_bars, (i) {
      final envelope = 0.35 + 0.65 * math.sin((i / _bars) * math.pi);
      return (0.22 + rng.nextDouble() * 0.78) * envelope;
    });
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(() {
        if (_playing && mounted) setState(() {});
      });

    _posSub = _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _doneSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _pulse.stop();
      setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final playing = state == PlayerState.playing;
      setState(() => _playing = playing);
      if (playing) {
        _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LifeSkillListenBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _stopAndReset();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _doneSub?.cancel();
    _stateSub?.cancel();
    _pulse.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _stopAndReset() async {
    await _player.stop();
    _pulse.stop();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _loading = false;
      _failed = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedUrl = null;
    });
  }

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    if (_playing) {
      await _player.pause();
      return;
    }

    final url = widget.audioUrl.trim();
    if (url.isEmpty) {
      setState(() => _failed = true);
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      if (_loadedUrl != url) {
        await _player.stop();
        await _player.play(UrlSource(url));
        _loadedUrl = url;
      } else {
        await _player.resume();
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = false;
        _failed = true;
      });
    }
  }

  Future<void> _seekFraction(double fraction) async {
    if (_duration.inMilliseconds <= 0) return;
    final ms = (_duration.inMilliseconds * fraction.clamp(0.0, 1.0)).round();
    await _player.seek(Duration(milliseconds: ms));
  }

  String _fmt(Duration d) {
    final total = d.inSeconds.clamp(0, 60 * 60 * 10);
    final m = total ~/ 60;
    final s = total % 60;
    // Life Skill always uses English digits for times.
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    const gold = Color(0xFFE8C547);
    const goldDeep = Color(0xFFC9A227);
    const ink = Color(0xFF14110D);
    final rim = Color.lerp(gold, widget.accent, 0.2)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1812), Color(0xFF0F0D0A)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rim.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: goldDeep.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Material(
                color: gold,
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _loading ? null : _toggle,
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: ink,
                              ),
                            )
                          : Icon(
                              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: ink,
                              size: 30,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: _Waveform(
                        heights: _heights,
                        progress: progress,
                        playing: _playing,
                        pulse: _pulse.value,
                        active: gold,
                        idle: gold.withValues(alpha: 0.22),
                        onSeek: _duration.inMilliseconds > 0 ? _seekFraction : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _fmt(_position),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: gold.withValues(alpha: 0.85),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        if (_failed)
                          Text(
                            tr(widget.bn, 'লোড হয়নি', 'Failed'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFCA5A5),
                            ),
                          )
                        else
                          Text(
                            _fmt(_duration),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: gold.withValues(alpha: 0.55),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  final List<double> heights;
  final double progress;
  final bool playing;
  final double pulse;
  final Color active;
  final Color idle;
  final ValueChanged<double>? onSeek;

  const _Waveform({
    required this.heights,
    required this.progress,
    required this.playing,
    required this.pulse,
    required this.active,
    required this.idle,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null
              ? null
              : (d) => onSeek!(d.localPosition.dx / box.maxWidth),
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (d) => onSeek!(d.localPosition.dx / box.maxWidth),
          child: CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _WavePainter(
              heights: heights,
              progress: progress,
              playing: playing,
              pulse: pulse,
              active: active,
              idle: idle,
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> heights;
  final double progress;
  final bool playing;
  final double pulse;
  final Color active;
  final Color idle;

  const _WavePainter({
    required this.heights,
    required this.progress,
    required this.playing,
    required this.pulse,
    required this.active,
    required this.idle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = heights.length;
    if (n == 0 || size.width <= 0) return;
    final gap = size.width / (n * 2.2);
    final barW = math.max(2.0, (size.width - gap * (n - 1)) / n);
    final midY = size.height / 2;
    final playedUntil = progress * n;

    for (var i = 0; i < n; i++) {
      var h = heights[i] * size.height * 0.92;
      if (playing) {
        final wave = 0.82 + 0.18 * math.sin((i * 0.55) + pulse * math.pi * 2);
        h *= wave;
      }
      h = h.clamp(4.0, size.height);
      final x = i * (barW + gap);
      final played = i + 1 <= playedUntil;
      final paint = Paint()
        ..color = played ? active : idle
        ..style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + barW / 2, midY), width: barW, height: h),
        const Radius.circular(99),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) {
    return old.progress != progress ||
        old.playing != playing ||
        old.pulse != pulse ||
        old.active != active ||
        old.idle != idle;
  }
}
