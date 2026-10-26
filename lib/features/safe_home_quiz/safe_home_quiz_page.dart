import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/bangla_read_aloud.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'safe_home_quiz_engine.dart';
import 'safe_home_quiz_models.dart';

/// Simple SAFE HOME quiz: snapped conductor, site variant, time + score rings.
class SafeHomeQuizPage extends StatefulWidget {
  const SafeHomeQuizPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const SafeHomeQuizPage()),
      );

  @override
  State<SafeHomeQuizPage> createState() => _SafeHomeQuizPageState();
}

class _SafeHomeQuizPageState extends State<SafeHomeQuizPage> with TickerProviderStateMixin {
  SafeHomeQuizEngine? _engine;
  final _tts = BanglaReadAloud();
  Timer? _clock;
  Timer? _shuffleTimer;

  List<ShOption> _opts = [];
  final _picked = <ShOption>[];
  String? _flash;
  Color _flashColor = ZlColors.amber;
  String? _hintText;
  var _hintAvailable = false;
  var _hintOpen = false;
  var _shake = 0;
  var _loading = true;
  var _muted = false;
  var _burstOk = true;
  var _burstKey = 0;
  var _clockHeld = false;

  late final AnimationController _ringPulse;
  late final AnimationController _introPop;
  late final AnimationController _penaltyFlash;
  late final AnimationController _spark;
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _ringPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _introPop = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _penaltyFlash = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _spark = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _boot();
  }

  Future<void> _boot() async {
    final pack = await SafeHomePack.load();
    final engine = SafeHomeQuizEngine(pack);
    setState(() {
      _engine = engine;
      _loading = false;
    });
    _introPop.forward(from: 0);
    unawaited(ZlMusic.start());
    await _speak(engine.site.introBn);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _shuffleTimer?.cancel();
    _ringPulse.dispose();
    _introPop.dispose();
    _penaltyFlash.dispose();
    _spark.dispose();
    _burst.dispose();
    _tts.stop();
    if (_clockHeld) ZlFx.releaseClock();
    ZlMusic.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (_muted || text.trim().isEmpty) return;
    await _tts.speakAwait(text, rate: 0.42);
  }

  void _startQuiz() {
    final e = _engine;
    if (e == null) return;
    HapticFeedback.mediumImpact();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.55, muted: _muted));
    e.beginQuiz();
    if (!_clockHeld) {
      _clockHeld = true;
      ZlFx.holdClock();
    }
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _engine == null) return;
      final ended = _engine!.tick();
      setState(() {});
      if (ended) _onDone();
    });
    _loadStep(speak: true);
  }

  void _loadStep({required bool speak}) {
    final e = _engine;
    final s = e?.step;
    if (e == null || s == null) {
      setState(() {});
      return;
    }
    _picked.clear();
    _hintAvailable = false;
    _hintOpen = false;
    _hintText = null;
    _refreshPool(s);
    _startShuffleLoop();
    setState(() {});
    if (speak) unawaited(_speak(s.promptBn));
  }

  void _refreshPool(ShStep s) {
    final taken = _picked.map((o) => o.id).toSet();
    _opts = [...s.options.where((o) => !taken.contains(o.id))]..shuffle(Random());
  }

  void _startShuffleLoop() {
    _shuffleTimer?.cancel();
    unawaited(ZlFx.cue('sounds/quiz_shuffle.wav', volume: 0.35, muted: _muted));
    // Reshuffle only unselected pool options.
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      final e = _engine;
      final s = e?.step;
      if (e == null || s == null || e.phase != ShPhase.quiz) return;
      setState(() => _refreshPool(s));
      unawaited(ZlFx.cue('sounds/quiz_shuffle.wav', volume: 0.28, muted: _muted));
    });
  }

  void _stopShuffle() {
    _shuffleTimer?.cancel();
  }

  void _showFlash(String text, Color color, {bool shake = false}) {
    setState(() {
      _flash = text;
      _flashColor = color;
      if (shake) _shake++;
    });
    if (shake) {
      _penaltyFlash.forward(from: 0);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  void _submitSingle(String id) {
    final e = _engine;
    final s = e?.step;
    if (e == null || s == null || e.phase != ShPhase.quiz) return;
    _stopShuffle();
    final r = e.answerSingle(id);
    _handleResult(r);
  }

  void _toggleMulti(String id) {
    final s = _engine?.step;
    if (s == null) return;
    HapticFeedback.selectionClick();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.45, muted: _muted));
    setState(() {
      final i = _picked.indexWhere((o) => o.id == id);
      if (i >= 0) {
        _picked.removeAt(i);
      } else {
        for (final o in s.options) {
          if (o.id == id) {
            _picked.add(o);
            break;
          }
        }
      }
      _refreshPool(s);
    });
  }

  void _submitMulti() {
    final e = _engine;
    final s = e?.step;
    if (e == null || s == null || e.phase != ShPhase.quiz) return;
    if (_picked.isEmpty) {
      _showFlash('কমপক্ষে একটি বাছুন', ZlColors.orange, shake: true);
      return;
    }
    _stopShuffle();
    final r = e.answerMulti(_picked.map((o) => o.id).toSet());
    _handleResult(r);
  }

  void _showHint() {
    final s = _engine?.step;
    if (!_hintAvailable || s == null) return;
    final text = s.hintBn.isEmpty ? 'আবার ভেবে দেখুন।' : s.hintBn;
    HapticFeedback.selectionClick();
    setState(() {
      _hintOpen = true;
      _hintText = text;
    });
    unawaited(_speak(text));
  }

  void _handleResult(ShAnswerResult r) {
    _burstOk = r.ok;
    _burstKey++;
    _burst.forward(from: 0);
    if (r.ok) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', muted: _muted));
      _showFlash(r.noteBn, ZlColors.green);
      setState(() {
        _hintAvailable = false;
        _hintOpen = false;
        _hintText = null;
      });
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || _engine == null) return;
        if (_engine!.finished) {
          _onDone();
        } else if (_engine!.phase == ShPhase.quiz) {
          _loadStep(speak: true);
        } else {
          setState(() {});
        }
      });
    } else {
      unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: _muted));
      _showFlash(r.noteBn, ZlColors.red, shake: true);
      setState(() {
        _hintAvailable = true;
        _hintOpen = false;
        // Keep multi picks; reshuffle remaining pool for another try.
        final s = _engine?.step;
        if (s != null) _refreshPool(s);
      });
      _startShuffleLoop();
    }
  }

  void _dismissDisturbance() {
    final e = _engine;
    if (e == null) return;
    final line = e.activeDisturbance?.lineBn ?? '';
    e.dismissDisturbance();
    unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.5, muted: _muted));
    _showFlash('ব্যাঘাত · পেনাল্টি', ZlColors.orange, shake: true);
    setState(() {});
    if (e.finished) {
      _onDone();
    } else {
      unawaited(_speak(line));
      _loadStep(speak: false);
    }
  }

  void _onDone() {
    _stopShuffle();
    _clock?.cancel();
    if (_clockHeld) {
      ZlFx.stopClock();
      _clockHeld = false;
    }
    unawaited(ZlFx.cue('sounds/quiz_complete.wav', muted: _muted));
    _burstOk = true;
    _burstKey++;
    _burst.forward(from: 0);
    setState(() {});
    unawaited(_speak(_engine?.gradeBn() ?? ''));
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZlColors.panel,
        title: Text('বের হবেন?', style: zlText(18, weight: FontWeight.w900)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('না', style: zlText(14))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('হ্যাঁ', style: zlText(14, color: ZlColors.red))),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _engine == null) {
      return const Scaffold(
        backgroundColor: ZlColors.bg,
        body: Center(child: CircularProgressIndicator(color: ZlColors.amber)),
      );
    }
    final e = _engine!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: ZlColors.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Scene
            Image.asset(
              e.site.bg,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.bg),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),

            // Live-wire spark wash
            AnimatedBuilder(
              animation: _spark,
              builder: (_, _) => IgnorePointer(
                child: CustomPaint(
                  painter: _WireSparkPainter(t: _spark.value, hot: e.phase == ShPhase.quiz || e.phase == ShPhase.intro),
                  size: Size.infinite,
                ),
              ),
            ),

            // Penalty red wash
            AnimatedBuilder(
              animation: _penaltyFlash,
              builder: (_, _) => IgnorePointer(
                child: ColoredBox(
                  color: ZlColors.red.withValues(alpha: 0.25 * (1 - _penaltyFlash.value)),
                ),
              ),
            ),

            // Answer / finish burst
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, _) => CustomPaint(
                  key: ValueKey(_burstKey),
                  painter: _BurstPainter(t: _burst.value, ok: _burstOk),
                  size: Size.infinite,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    title: e.pack.titleBn,
                    site: e.site.nameBn,
                    muted: _muted,
                    onMute: () async {
                      setState(() => _muted = !_muted);
                      ZlFx.setMuted(_muted);
                      await ZlMusic.setMuted(_muted);
                      if (_muted) _tts.stop();
                    },
                    onClose: _confirmExit,
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _ringPulse,
                    builder: (_, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GlowRing(
                          label: 'সময়',
                          value: _fmtTime(e.secondsLeft),
                          color: e.secondsLeft <= 30 ? ZlColors.red : ZlColors.blue,
                          pulse: _ringPulse.value,
                          progress: e.secondsLeft / e.pack.timeSeconds,
                          danger: e.secondsLeft <= 30,
                        ),
                        const SizedBox(width: 22),
                        _GlowRing(
                          label: 'স্কোর',
                          value: '${e.score}',
                          color: ZlColors.amber,
                          pulse: _ringPulse.value,
                          progress: (e.rightSteps.length / max(1, e.totalSteps)).clamp(0.05, 1.0),
                        ),
                      ],
                    ),
                  ),
                  if (_flash != null) ...[
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_flash),
                      tween: Tween(begin: 0.8, end: 1),
                      duration: const Duration(milliseconds: 280),
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _flashColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: _flashColor.withValues(alpha: 0.55), blurRadius: 18),
                          ],
                        ),
                        child: Text(_flash!, style: zlText(15, weight: FontWeight.w900, color: ZlColors.bg)),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (e.phase == ShPhase.intro) _IntroCard(engine: e, pop: _introPop, onGo: _startQuiz),
                            if (e.phase == ShPhase.quiz && e.step != null)
                              _QuizCard(
                                step: e.step!,
                                stepNo: e.stepIndex + 1,
                                total: e.totalSteps,
                                pool: _opts,
                                picked: _picked,
                                shakeToken: _shake,
                                hintAvailable: _hintAvailable,
                                hintOpen: _hintOpen,
                                hintText: _hintText,
                                onSingle: _submitSingle,
                                onToggle: _toggleMulti,
                                onConfirmMulti: _submitMulti,
                                onHint: _showHint,
                              ),
                            if (e.phase == ShPhase.disturbance && e.activeDisturbance != null)
                              _DisturbanceCard(d: e.activeDisturbance!, onDismiss: _dismissDisturbance),
                            if (e.phase == ShPhase.done)
                              _ScoreCard(engine: e, onClose: () => Navigator.of(context).pop()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(1, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String site;
  final bool muted;
  final VoidCallback onMute;
  final VoidCallback onClose;

  const _TopBar({
    required this.title,
    required this.site,
    required this.muted,
    required this.onMute,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: ZlColors.soft)),
          Expanded(
            child: Column(
              children: [
                Text(title, style: zlText(15, weight: FontWeight.w900)),
                Text(site, style: zlText(12, color: ZlColors.amber)),
              ],
            ),
          ),
          IconButton(
            onPressed: onMute,
            icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: ZlColors.soft),
          ),
        ],
      ),
    );
  }
}

class _GlowRing extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double pulse;
  final double progress;
  final bool danger;

  const _GlowRing({
    required this.label,
    required this.value,
    required this.color,
    required this.pulse,
    this.progress = 1,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 8.0 + 10.0 * pulse;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(92, 92),
                painter: _RingArcPainter(progress: progress.clamp(0.0, 1.0), color: color, pulse: pulse),
              ),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xE0141C2C),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: danger ? 0.6 : 0.35), blurRadius: glow),
                  ],
                ),
                child: Text(value, style: zlText(22, weight: FontWeight.w900, color: color)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: zlText(12, weight: FontWeight.w800, color: ZlColors.soft)),
      ],
    );
  }
}

class _RingArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double pulse;

  _RingArcPainter({required this.progress, required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color.withValues(alpha: 0.85 + 0.15 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingArcPainter old) =>
      old.progress != progress || old.color != color || old.pulse != pulse;
}

class _WireSparkPainter extends CustomPainter {
  final double t;
  final bool hot;

  _WireSparkPainter({required this.t, required this.hot});

  @override
  void paint(Canvas canvas, Size size) {
    if (!hot || size.isEmpty) return;
    final rnd = Random(42);
    for (var i = 0; i < 10; i++) {
      final phase = (t + i * 0.11) % 1.0;
      final x = size.width * (0.15 + rnd.nextDouble() * 0.7);
      final y = size.height * (0.18 + rnd.nextDouble() * 0.35);
      final a = (1 - phase) * (i.isEven ? 0.55 : 0.3);
      final p = Paint()
        ..color = Color.lerp(ZlColors.amber, Colors.white, phase)!.withValues(alpha: a)
        ..strokeWidth = 1.4 + 2.2 * (1 - phase)
        ..strokeCap = StrokeCap.round;
      final len = 8.0 + 18.0 * (1 - phase);
      canvas.drawLine(Offset(x, y), Offset(x + len * (i.isEven ? 1 : -0.6), y + len * 0.4), p);
      canvas.drawCircle(Offset(x, y), 1.5 + 2 * (1 - phase), p..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _WireSparkPainter old) => old.t != t || old.hot != hot;
}

class _BurstPainter extends CustomPainter {
  final double t;
  final bool ok;

  _BurstPainter({required this.t, required this.ok});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1 || size.isEmpty) return;
    final c = Offset(size.width / 2, size.height * 0.42);
    final color = ok ? ZlColors.green : ZlColors.red;
    for (var i = 0; i < 14; i++) {
      final ang = (i / 14) * 2 * pi + t * 0.8;
      final dist = 28 + 90 * Curves.easeOut.transform(t);
      final p = Offset(c.dx + cos(ang) * dist, c.dy + sin(ang) * dist);
      final paint = Paint()..color = color.withValues(alpha: (1 - t) * 0.85);
      canvas.drawCircle(p, 3.5 * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t || old.ok != ok;
}

class _IntroCard extends StatelessWidget {
  final SafeHomeQuizEngine engine;
  final AnimationController pop;
  final VoidCallback onGo;

  const _IntroCard({required this.engine, required this.pop, required this.onGo});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: pop, curve: Curves.easeOutBack),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xF0131C2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ZlColors.amber.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text('SAFE HOME', style: zlText(22, weight: FontWeight.w900, color: ZlColors.amber)),
            const SizedBox(height: 6),
            Text(engine.pack.subtitleBn, style: zlText(13, color: ZlColors.soft)),
            const SizedBox(height: 12),
            Text(engine.site.introBn, textAlign: TextAlign.center, style: zlText(15, weight: FontWeight.w700, height: 1.35)),
            const SizedBox(height: 16),
            ZlButton(label: 'শুরু · কুইজ', icon: Icons.play_arrow_rounded, onTap: onGo),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final ShStep step;
  final int stepNo;
  final int total;
  final List<ShOption> pool;
  final List<ShOption> picked;
  final int shakeToken;
  final bool hintAvailable;
  final bool hintOpen;
  final String? hintText;
  final ValueChanged<String> onSingle;
  final ValueChanged<String> onToggle;
  final VoidCallback onConfirmMulti;
  final VoidCallback onHint;

  const _QuizCard({
    required this.step,
    required this.stepNo,
    required this.total,
    required this.pool,
    required this.picked,
    required this.shakeToken,
    required this.hintAvailable,
    required this.hintOpen,
    required this.hintText,
    required this.onSingle,
    required this.onToggle,
    required this.onConfirmMulti,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final multi = step.kind == ShKind.multi;
    return TweenAnimationBuilder<double>(
      key: ValueKey('$shakeToken-${step.id}'),
      tween: Tween(begin: shakeToken > 0 ? -8.0 : 0, end: 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (_, x, child) => Transform.translate(offset: Offset(x, 0), child: child),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xF0131C2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ZlColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _MantraChip(id: step.mantra),
                const SizedBox(width: 8),
                Text('$stepNo / $total', style: zlText(12, color: ZlColors.soft)),
                const Spacer(),
                if (hintAvailable)
                  TextButton.icon(
                    onPressed: onHint,
                    icon: const Icon(Icons.lightbulb_outline_rounded, color: ZlColors.amber, size: 18),
                    label: Text('হিন্ট', style: zlText(12, weight: FontWeight.w800, color: ZlColors.amber)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  )
                else
                  const Icon(Icons.shuffle_rounded, color: ZlColors.amber, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(step.promptBn, textAlign: TextAlign.center, style: zlText(16, weight: FontWeight.w900, height: 1.3)),
            if (hintOpen && hintText != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ZlColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ZlColors.amber.withValues(alpha: 0.45)),
                ),
                child: Text(hintText!, textAlign: TextAlign.center, style: zlText(13, weight: FontWeight.w700, height: 1.3, color: ZlColors.amber)),
              ),
            ],
            if (multi) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('নির্বাচিত', style: zlText(12, weight: FontWeight.w800, color: ZlColors.soft)),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 88),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ZlColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ZlColors.amber.withValues(alpha: 0.4), width: 1.4),
                ),
                child: picked.isEmpty
                    ? Center(child: Text('এখানে ট্যাপ করে রাখুন', style: zlText(12, color: ZlColors.soft)))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final o in picked)
                            _OptionTile(
                              option: o,
                              selected: true,
                              multi: true,
                              compact: true,
                              onTap: () => onToggle(o.id),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('বাকি অপশন', style: zlText(12, weight: FontWeight.w800, color: ZlColors.soft)),
              ),
              const SizedBox(height: 6),
            ] else
              const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final o in pool)
                  _OptionTile(
                    option: o,
                    selected: false,
                    multi: multi,
                    onTap: () => multi ? onToggle(o.id) : onSingle(o.id),
                  ),
              ],
            ),
            if (multi) ...[
              const SizedBox(height: 12),
              ZlButton(
                label: picked.isEmpty ? 'বাছুন' : 'নিশ্চিত · ${picked.length}টি',
                icon: Icons.check_rounded,
                onTap: picked.isEmpty ? null : onConfirmMulti,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MantraChip extends StatelessWidget {
  final String id;
  const _MantraChip({required this.id});

  @override
  Widget build(BuildContext context) {
    final c = mantraColor(id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: c)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mantraIcon(id), size: 14, color: c),
          const SizedBox(width: 4),
          Text(id.toUpperCase(), style: zlText(11, weight: FontWeight.w900, color: c)),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final ShOption option;
  final bool selected;
  final bool multi;
  final bool compact;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.multi,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = option.image.isNotEmpty;
    final w = compact ? 86.0 : (hasImg ? 108.0 : 148.0);
    final imgH = compact ? 48.0 : 64.0;
    return Material(
      color: selected ? ZlColors.amber.withValues(alpha: 0.2) : ZlColors.panelHi,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: w,
          padding: EdgeInsets.all(compact ? 8 : 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? ZlColors.amber : ZlColors.line, width: selected ? 2.2 : 1),
          ),
          child: Column(
            children: [
              if (hasImg)
                SizedBox(
                  height: imgH,
                  child: Image.asset(
                    option.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(Icons.handyman_rounded, color: ZlColors.soft, size: compact ? 28 : 36),
                  ),
                )
              else
                Icon(Icons.touch_app_rounded, color: selected ? ZlColors.amber : ZlColors.soft, size: compact ? 22 : 28),
              const SizedBox(height: 6),
              Text(
                option.labelBn,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: zlText(compact ? 11 : 12, weight: FontWeight.w800, color: selected ? ZlColors.amber : ZlColors.text),
              ),
              if (multi && selected) const Icon(Icons.close_rounded, size: 14, color: ZlColors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisturbanceCard extends StatelessWidget {
  final ShDisturbance d;
  final VoidCallback onDismiss;

  const _DisturbanceCard({required this.d, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ZlColors.red.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: ZlColors.red.withValues(alpha: 0.45), blurRadius: 24)],
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text('ব্যাঘাত!', style: zlText(20, weight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(d.lineBn, textAlign: TextAlign.center, style: zlText(15, weight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          ZlButton(label: 'বুঝেছি · চালিয়ে যান', icon: Icons.arrow_forward_rounded, color: Colors.white, onTap: onDismiss),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final SafeHomeQuizEngine engine;
  final VoidCallback onClose;

  const _ScoreCard({required this.engine, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xF0131C2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ZlColors.amber, width: 1.6),
          boxShadow: [
            BoxShadow(color: ZlColors.amber.withValues(alpha: 0.35), blurRadius: 28),
          ],
        ),
        child: Column(
          children: [
            Text('স্কোরকার্ড', style: zlText(20, weight: FontWeight.w900, color: ZlColors.amber)),
            const SizedBox(height: 6),
            Text(engine.site.nameBn, style: zlText(13, color: ZlColors.soft)),
            const SizedBox(height: 14),
            Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ZlColors.amber, width: 3),
                boxShadow: [
                  BoxShadow(color: ZlColors.amber.withValues(alpha: 0.45), blurRadius: 22),
                ],
              ),
              child: Text('${engine.score}', style: zlText(42, weight: FontWeight.w900, color: ZlColors.amber)),
            ),
            const SizedBox(height: 10),
            Text(engine.gradeBn(), style: zlText(16, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'ঠিক ${engine.rightSteps.length}/${engine.totalSteps} · ভুল ধাপ ${engine.wrongSteps.length}',
              style: zlText(13, color: ZlColors.soft),
            ),
            const SizedBox(height: 16),
            ZlButton(label: 'শেষ', icon: Icons.check_rounded, onTap: onClose),
          ],
        ),
      ),
    );
  }
}
