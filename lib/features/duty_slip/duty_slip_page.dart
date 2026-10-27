import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/bangla_read_aloud.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'ds_dress_up.dart';
import 'duty_slip_engine.dart';
import 'duty_slip_models.dart';
import 'duty_slip_voice.dart';

class DutySlipPage extends StatefulWidget {
  const DutySlipPage({super.key});

  static Future<void> open(BuildContext context, {Rect? sourceRect}) =>
      Navigator.of(context, rootNavigator: true).push(
        _DramaticGamePageRoute(
          page: const DutySlipPage(),
          sourceRect: sourceRect,
        ),
      );

  @override
  State<DutySlipPage> createState() => _DutySlipPageState();
}

class _DramaticGamePageRoute extends PageRouteBuilder<void> {
  final Widget page;
  final Rect? sourceRect;

  _DramaticGamePageRoute({required this.page, this.sourceRect})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _DramaticPortalTransition(
              animation: animation,
              sourceRect: sourceRect,
              child: child,
            );
          },
        );
}

class _DramaticPortalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect? sourceRect;
  final Widget child;

  const _DramaticPortalTransition({
    required this.animation,
    required this.sourceRect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = sourceRect?.center ?? size.center(Offset.zero);

    final dX = math.max(center.dx, size.width - center.dx);
    final dY = math.max(center.dy, size.height - center.dy);
    final maxRadius = math.sqrt(dX * dX + dY * dY) * 1.08;
    final minRadius = sourceRect != null ? (sourceRect!.width / 2).clamp(16.0, 48.0) : 24.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.fastOutSlowIn.transform(animation.value);
        final currentRadius = ui.lerpDouble(minRadius, maxRadius, t)!;
        final scale = 0.88 + 0.12 * Curves.easeOutCubic.transform(animation.value);
        final flashAlpha = (animation.value < 0.35
                ? (animation.value / 0.35)
                : ((1.0 - animation.value) / 0.65))
            .clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
              clipper: _PortalCircleClipper(center: center, radius: currentRadius),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment(
                  (center.dx / size.width) * 2 - 1,
                  (center.dy / size.height) * 2 - 1,
                ),
                child: child,
              ),
            ),
            if (animation.value < 0.98)
              IgnorePointer(
                child: CustomPaint(
                  painter: _PortalShockwavePainter(
                    center: center,
                    radius: currentRadius,
                    progress: animation.value,
                  ),
                ),
              ),
            if (flashAlpha > 0.01)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        (center.dx / size.width) * 2 - 1,
                        (center.dy / size.height) * 2 - 1,
                      ),
                      radius: 0.9,
                      colors: [
                        Color.fromRGBO(251, 191, 36, 0.42 * flashAlpha),
                        Color.fromRGBO(245, 158, 11, 0.18 * flashAlpha),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PortalCircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _PortalCircleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_PortalCircleClipper old) => old.center != center || old.radius != radius;
}

class _PortalShockwavePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double progress;

  const _PortalShockwavePainter({
    required this.center,
    required this.radius,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1.0 - progress).clamp(0.0, 1.0);
    final haloPaint = Paint()
      ..color = Color.fromRGBO(251, 191, 36, 0.72 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 + 12 * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius, haloPaint);

    final corePaint = Paint()
      ..color = Color.fromRGBO(255, 247, 214, 0.96 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, corePaint);
  }

  @override
  bool shouldRepaint(_PortalShockwavePainter old) =>
      old.radius != radius || old.progress != progress;
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
  final _jobTick = ValueNotifier(0);
  final _scoreKey = GlobalKey();
  final _stackKey = GlobalKey();
  Timer? _clock;
  late final AnimationController _shake;
  late final Animation<double> _shakeX;
  List<DsOption> _opts = [];
  String? _hint;
  var _hintOn = false;
  var _hintOpen = false;
  var _loading = true;
  var _muted = false;
  var _kitI = 0;
  final _yes = <String>{};
  var _callOpen = false;
  String? _ptwFeeder;
  String? _ptwPole;
  String? _ptwShift;
  var _ynKey = 0;
  var _clockHeld = false;
  var _loadingWaitOpenRoad = false;
  var _flyId = 0;
  final _flies = <_FlyBit>[];

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
    _boot();
  }

  Future<void> _boot() async {
    final pack = await DsPack.load();
    final engine = DutySlipEngine(pack);
    await engine.loadPersistedState();
    if (_loadingWaitOpenRoad) {
      engine.openRoad();
    }
    if (!mounted) return;
    setState(() {
      _engine = engine;
      _loading = false;
    });
    unawaited(ZlMusic.start());
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final e = _engine;
      if (e == null || e.act == DsAct.done || e.act == DsAct.lethal) return;
      e.addJobSeconds(2);
      e.tickPlay(100);
      _jobTick.value++;
    });
  }

  void _openRoad() {
    final e = _engine;
    if (e == null) {
      _loadingWaitOpenRoad = true;
      return;
    }
    e.openRoad();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: _muted));
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _openLevel(int index) {
    final e = _engine;
    if (e == null || !e.onRoad) return;
    e.openLevel(index);
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _backToRoad() {
    final e = _engine;
    if (e == null) return;
    DsVoice.stop();
    _tts.stop();
    e.backToRoad();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: _muted));
    _holdClock(false);
    setState(() {});
  }

  void _finishSafeWalk() {
    final e = _engine;
    if (e == null || !e.showingDress) return;
    e.finishDress();
    _holdClock(false);
    setState(() {});
  }

  void _openDress() {
    final e = _engine;
    if (e == null || !e.showingDressIntro) return;
    DsVoice.stop();
    _tts.stop();
    e.openDress();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.45, muted: _muted));
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
      unawaited(ZlFx.cue('sounds/quiz_shuffle.wav', muted: _muted));
    } else {
      _holdClock(true);
      unawaited(ZlFx.cue('sounds/quiz_flip.wav', muted: _muted));
      unawaited(_speak('ডকেট পড়ে নিন।'));
    }
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _retryLevel() {
    final e = _engine;
    if (e == null || !e.showingResult) return;
    e.replayNow();
    if (e.playing) _holdClock(true);
    if (!e.showingDressIntro) unawaited(ZlFx.cue('sounds/quiz_shuffle.wav', muted: _muted));
    setState(() {});
  }

  void _showLevelList() {
    final e = _engine;
    if (e == null || !e.showingResult) return;
    e.retryPlay();
    _holdClock(false);
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.45, muted: _muted));
    setState(() {});
  }

  void _nextLevel() {
    final e = _engine;
    if (e == null || !e.showingResult) return;
    e.nextAfterPass();
    _holdClock(false);
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', muted: _muted));
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  @override
  void dispose() {
    _clock?.cancel();
    _jobTick.dispose();
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
    final clean = _engine?.fill(text) ?? text;
    final played = await DsVoice.play(clean, muted: _muted);
    if (!played) {
      await _tts.speakAwait(clean, rate: 0.42);
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
    final from = _stackLocal(fromGlobal ?? Offset(size.width / 2, size.height * 0.55));
    final to = _scoreTarget();
    final id = ++_flyId;
    setState(() => _flies.add(_FlyBit(id: id, delta: delta, from: from, to: to)));
    Future<void>.delayed(const Duration(milliseconds: 720), () {
      if (!mounted) return;
      setState(() => _flies.removeWhere((f) => f.id == id));
    });
  }

  void _handle(DsResult r, {Offset? fromGlobal}) {
    final e = _engine;
    if (e == null) return;
    if (r.delta != 0) _flyDelta(r.delta, fromGlobal: fromGlobal);
    if (r.ok) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', muted: _muted));
      HapticFeedback.lightImpact();
      if (e.act == DsAct.call) {
        _callOpen = false;
        unawaited(ZlFx.cue('sounds/complaint.wav', volume: 0.85, muted: _muted));
        setState(() {});
        unawaited(_speak(e.activeCall?.lineBn ?? ''));
        return;
      }
      if (e.act == DsAct.done || e.act == DsAct.lethal) {
        _holdClock(false);
        unawaited(ZlFx.cue('sounds/quiz_complete.wav', muted: _muted));
      }
      _loadCard(speak: true);
    } else if (r.lethal || e.act == DsAct.lethal) {
      _holdClock(false);
      unawaited(ZlFx.cue('sounds/accident.wav', muted: _muted));
      HapticFeedback.heavyImpact();
      setState(() {});
      unawaited(_speak(e.lethalReason ?? r.noteBn));
    } else {
      unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: _muted));
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      _hintOn = true;
      setState(() {});
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
    _handle(e.answerSingle(id), fromGlobal: global);
  }

  void _answerYn(bool take, Offset global) {
    final e = _engine;
    final s = e?.step;
    if (e == null || s == null || s.kind != DsKind.kit) return;
    if (_kitI >= _opts.length) return;
    final o = _opts[_kitI];
    final must = s.essential.contains(o.id);
    final ban = s.forbidden.contains(o.id);
    final ok = must ? take : ban ? !take : true;
    if (take) _yes.add(o.id);
    if (ok) {
      e.addScore(5);
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: _muted));
      HapticFeedback.selectionClick();
      _flyDelta(5, fromGlobal: global);
    } else {
      e.addScore(-5);
      e.safety = (e.safety - 5).clamp(0, 100);
      e.jumpMinutes(5);
      unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: _muted));
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
      unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.45, muted: _muted));
    }
  }

  void _tapPlan(String id, Offset global) {
    final e = _engine;
    if (e == null) return;
    final r = e.tapPlan(id);
    if (r.ok) {
      unawaited(ZlFx.cue('sounds/quiz_select.wav', muted: _muted));
      if (r.streak >= 3) {
        unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.35, muted: _muted));
      }
      if (r.gift) {
        unawaited(ZlFx.cue('sounds/quiz_right.wav', muted: _muted));
      }
      HapticFeedback.lightImpact();
      _flyDelta(r.delta, fromGlobal: global);
      if (e.showingResult) {
        _holdClock(false);
      }
    } else {
      unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: _muted));
      if (e.level.living) {
        unawaited(ZlFx.cue('sounds/quiz_shuffle.wav', volume: 0.55, muted: _muted));
      }
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      _flyDelta(r.delta, fromGlobal: global);
    }
    setState(() {});
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZlColors.panel,
        title: Text('বের হবেন?', style: zlText(18, weight: FontWeight.w800)),
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
      return Scaffold(
        backgroundColor: ZlColors.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/duty_slip/duty_fault_slip.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.bg),
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
            SafeArea(
              child: _CoverBoard(
                onOpen: () {
                  if (_engine != null) {
                    _openRoad();
                  } else {
                    _loadingWaitOpenRoad = true;
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
    final e = _engine!;
    final jobIntro = e.listing && e.level.isJob;
    final walk = e.showingSafeWalk;
    final dress = e.showingDress;
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
            if (dress)
              const ColoredBox(color: Color(0xFFF6E2C2))
            else if (walk)
              const ColoredBox(color: Color(0xFFC5DCE8))
            else
              Image.asset(bg, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: ZlColors.bg)),
            if (!walk && !dress)
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
            SafeArea(
              child: Column(
                children: [
                  if (e.showHud)
                    ValueListenableBuilder<int>(
                      valueListenable: _jobTick,
                      builder: (_, _, _) => _Hud(
                        engine: e,
                        scoreKey: _scoreKey,
                        muted: _muted,
                        onMute: () async {
                          setState(() => _muted = !_muted);
                          ZlFx.setMuted(_muted);
                          await ZlMusic.setMuted(_muted);
                          if (_muted) _tts.stop();
                        },
                      ),
                    ),
                  if (e.stamps.contains('ptw'))
                    _PocketChip(feeder: e.feeder, alert: e.slashed.contains('feeder')),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _shakeX,
                      builder: (_, child) => Transform.translate(offset: Offset(_shakeX.value, 0), child: child),
                      child: switch (e.act) {
                        DsAct.briefing => _OfficeStage(
                            engine: e,
                            feeder: _ptwFeeder,
                            pole: _ptwPole,
                            shift: _ptwShift,
                            onPlan: _tapPlan,
                            onOpenRoad: _openRoad,
                            onOpenLevel: _openLevel,
                            onBackRoad: _backToRoad,
                            onFinishWalk: _finishSafeWalk,
                            onOpenDress: _openDress,
                            onStartLevel: _startLevel,
                            onRetry: _retryLevel,
                            onShowList: _showLevelList,
                            onNextLevel: _nextLevel,
                            muted: _muted,
                            onSpeak: _speak,
                            onDelta: _flyDelta,
                            onOpenPtw: () {
                              unawaited(ZlFx.cue('sounds/quiz_flip.wav', muted: _muted));
                              e.openPtw();
                              setState(() {});
                            },
                            onSetFeeder: (v) {
                              unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.35, muted: _muted));
                              setState(() => _ptwFeeder = v);
                            },
                            onSetPole: (v) {
                              unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.35, muted: _muted));
                              setState(() => _ptwPole = v);
                            },
                            onSetShift: (v) {
                              unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.35, muted: _muted));
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
                              final ok = e.submitPtw(feederPick: _ptwFeeder!, polePick: _ptwPole!, shiftPick: _ptwShift!);
                              if (ok) {
                                unawaited(ZlFx.cue('sounds/quiz_right.wav', muted: _muted));
                                _flyDelta(5, fromGlobal: g);
                                _loadCard(speak: true);
                              } else {
                                unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: _muted));
                                _shake.forward(from: 0);
                                _flyDelta(-5, fromGlobal: g);
                                setState(() {});
                              }
                            },
                          ),
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
                              unawaited(ZlFx.cue('sounds/quiz_flip.wav', muted: _muted));
                              setState(() => _callOpen = true);
                            },
                            onReply: (id, g) => _handle(e.answerCall(id), fromGlobal: g),
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
            for (final f in _flies) _FlyingScore(bit: f),
          ],
        ),
      ),
      ),
    );
  }
}

class _FlyingScore extends StatelessWidget {
  final _FlyBit bit;
  const _FlyingScore({required this.bit});

  @override
  Widget build(BuildContext context) {
    final plus = bit.delta > 0;
    final label = plus ? '+${bit.delta}' : '${bit.delta}';
    final color = plus ? ZlColors.green : ZlColors.red;
    return TweenAnimationBuilder<double>(
      key: ValueKey(bit.id),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      builder: (_, t, _) {
        final pos = Offset.lerp(bit.from, bit.to, t)!;
        final scale = 1.15 - (t * 0.35);
        final opacity = t < 0.85 ? 1.0 : (1 - t) / 0.15;
        return Positioned(
          left: pos.dx - 28,
          top: pos.dy - 14,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Text(label, style: zlText(22, weight: FontWeight.w900, color: color)),
            ),
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  final DutySlipEngine engine;
  final Key scoreKey;
  final bool muted;
  final VoidCallback onMute;
  const _Hud({required this.engine, required this.scoreKey, required this.muted, required this.onMute});

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final livePlay = e.playing || e.showingDress;
    final live = livePlay ? e.levelScore : e.quality;
    final liveColor = live < 0 ? ZlColors.red : ZlColors.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0xCC131C2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ZlColors.amber.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            _MuteDot(muted: muted, onMute: onMute),
            const SizedBox(width: 12),
            if (livePlay)
              Text(
                'লেভেল ${_bnNum(e.level.number)}',
                style: zlText(18, weight: FontWeight.w900, color: ZlColors.amber),
              ),
            const Spacer(),
            Text(
              e.playClock,
              style: zlText(20, weight: FontWeight.w900, color: e.overtime && !e.playing ? ZlColors.red : ZlColors.cream),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$live', key: scoreKey, style: zlText(24, weight: FontWeight.w900, color: liveColor, height: 1)),
                if (livePlay)
                  Text('${e.hudTotal}', style: zlText(12, weight: FontWeight.w700, color: ZlColors.soft, height: 1.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MuteDot extends StatelessWidget {
  final bool muted;
  final VoidCallback onMute;
  const _MuteDot({required this.muted, required this.onMute});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onMute,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ZlColors.line),
          ),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            size: 20,
            color: muted ? ZlColors.soft : ZlColors.cream,
          ),
        ),
      ),
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
  final VoidCallback onOpenRoad;
  final void Function(int index) onOpenLevel;
  final VoidCallback onBackRoad;
  final VoidCallback onFinishWalk;
  final VoidCallback onOpenDress;
  final VoidCallback onStartLevel;
  final VoidCallback onRetry;
  final VoidCallback onShowList;
  final VoidCallback onNextLevel;
  final VoidCallback onOpenPtw;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, {Offset? fromGlobal}) onDelta;
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
    required this.onOpenRoad,
    required this.onOpenLevel,
    required this.onBackRoad,
    required this.onFinishWalk,
    required this.onOpenDress,
    required this.onStartLevel,
    required this.onRetry,
    required this.onShowList,
    required this.onNextLevel,
    required this.onOpenPtw,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
    required this.onSetFeeder,
    required this.onSetPole,
    required this.onSetShift,
    required this.onSubmitPtw,
  });

  static const _ink = Color(0xFF1A140C);
  static const _mute = Color(0xFF6B6256);
  static const _wine = Color(0xFF7F1D1D);

  @override
  Widget build(BuildContext context) {
    final e = engine;
    if (e.briefingPage == 0) {
      return _PlanBoard(
        engine: e,
        onPlan: onPlan,
        onOpenRoad: onOpenRoad,
        onOpenLevel: onOpenLevel,
        onBackRoad: onBackRoad,
        onFinishWalk: onFinishWalk,
        onOpenDress: onOpenDress,
        onStartLevel: onStartLevel,
        onRetry: onRetry,
        onShowList: onShowList,
        onNextLevel: onNextLevel,
        muted: muted,
        onSpeak: onSpeak,
        onDelta: (delta, global) => onDelta(delta, fromGlobal: global),
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
                          child: Text(e.site.introBn, style: zlText(19, weight: FontWeight.w800, color: _ink, height: 1.35)),
                        ),
                      ),
                      Text('ছিঁড়ে পড়া ১১ কেভি কন্ডাক্টর', style: zlText(16, weight: FontWeight.w900, color: _ink)),
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

String _bnNum(int n) {
  if (n < 0) return '-${_bnNum(-n)}';
  const d = '০১২৩৪৫৬৭৮৯';
  return n.toString().split('').map((ch) {
    final idx = int.tryParse(ch);
    return idx != null ? d[idx] : ch;
  }).join();
}

String _bnCount(int n) => _bnNum(n);

String _groupMark(DsJobGroup g) => '${g.title}  ·  ${_bnCount(g.count)} ধাপ';

class _PlanBoard extends StatelessWidget {
  final DutySlipEngine engine;
  final void Function(String id, Offset global) onPlan;
  final VoidCallback onOpenRoad;
  final void Function(int index) onOpenLevel;
  final VoidCallback onBackRoad;
  final VoidCallback onFinishWalk;
  final VoidCallback onOpenDress;
  final VoidCallback onStartLevel;
  final VoidCallback onRetry;
  final VoidCallback onShowList;
  final VoidCallback onNextLevel;
  final bool muted;
  final Future<void> Function(String text) onSpeak;
  final void Function(int delta, Offset global) onDelta;

  const _PlanBoard({
    required this.engine,
    required this.onPlan,
    required this.onOpenRoad,
    required this.onOpenLevel,
    required this.onBackRoad,
    required this.onFinishWalk,
    required this.onOpenDress,
    required this.onStartLevel,
    required this.onRetry,
    required this.onShowList,
    required this.onNextLevel,
    required this.muted,
    required this.onSpeak,
    required this.onDelta,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    if (e.covering) return _CoverBoard(onOpen: onOpenRoad);
    if (e.onRoad) return _RoadBoard(engine: e, onOpen: onOpenLevel);
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
      if (e.showingDress) {
        return DsDressUp(
          key: ValueKey(e.level.number),
          engine: e,
          onDone: onFinishWalk,
          muted: muted,
          onSpeak: onSpeak,
          onDelta: onDelta,
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

// ─────────────────────────────────────────────────────────────────────────────
// জীবনের শিরস্ত্রাণ ও স্বর্ণবলয় (Lineman Safety Helmet with Golden Life Aureole)
// ─────────────────────────────────────────────────────────────────────────────

class _LifeHelmetAuraBadge extends StatelessWidget {
  final double pulse;
  final double size;
  const _LifeHelmetAuraBadge({this.pulse = 1.0, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HelmetAuraPainter(pulse: pulse),
        size: Size(size, size),
      ),
    );
  }
}

class _HelmetAuraPainter extends CustomPainter {
  final double pulse;
  const _HelmetAuraPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = w / 2;

    // 1. Outer Golden Aura Glow (স্বর্ণবলয় আভা)
    canvas.drawCircle(
      c,
      r * 0.95,
      Paint()
        ..color = Color.fromRGBO(245, 158, 11, 0.35 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // 2. Unbroken Golden Life-Ring (স্বর্ণবলয় - জীবনের সুরক্ষা বৃত্ত)
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFFFBE8),
          Color(0xFFFBBF24),
          Color(0xFFD97706),
          Color(0xFF92400E),
          Color(0xFFFDE68A),
          Color(0xFFFFFBE8),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.88))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawCircle(c, r * 0.88, ringPaint);

    // Inner subtle gold wire ring
    canvas.drawCircle(
      c,
      r * 0.80,
      Paint()
        ..color = const Color(0x66FDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 8 Golden Safety Beads along the circle (representing the 8 SAFE HOME steps)
    for (var i = 0; i < 8; i++) {
      final a = (i * math.pi * 2 / 8) - (math.pi / 2);
      final bx = c.dx + math.cos(a) * (r * 0.88);
      final by = c.dy + math.sin(a) * (r * 0.88);
      canvas.drawCircle(Offset(bx, by), 2.2, Paint()..color = const Color(0xFFFFFBE8));
    }

    // 3. Inner Dark Disc Background (contrast base for the golden helmet)
    canvas.drawCircle(
      c,
      r * 0.77,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3B1E05), Color(0xFF140A01)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.77)),
    );

    // 4. জীবনের শিরস্ত্রাণ (Lineman Electrical Safety Helmet with Chin-Strap)
    final scale = w / 100.0;
    final hc = c + Offset(0, -1.5 * scale);

    // A. Helmet Dome (Aerodynamic 3D dome)
    final dome = Path()
      ..moveTo(hc.dx - 24 * scale, hc.dy + 6 * scale)
      ..cubicTo(
        hc.dx - 26 * scale, hc.dy - 16 * scale,
        hc.dx - 14 * scale, hc.dy - 25 * scale,
        hc.dx, hc.dy - 25 * scale,
      )
      ..cubicTo(
        hc.dx + 14 * scale, hc.dy - 25 * scale,
        hc.dx + 26 * scale, hc.dy - 16 * scale,
        hc.dx + 24 * scale, hc.dy + 6 * scale,
      )
      ..close();

    final domeRect = Rect.fromCircle(center: hc, radius: 26 * scale);
    canvas.drawPath(
      dome,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFFFFBE8),
            Color(0xFFFBBF24),
            Color(0xFFF59E0B),
            Color(0xFFD97706),
            Color(0xFF92400E),
          ],
          stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
        ).createShader(domeRect),
    );

    // B. Central Impact-Deflection Ridge (মাঝের স্ট্রাকচারাল রিজ)
    final ridge = Path()
      ..moveTo(hc.dx - 2.5 * scale, hc.dy + 6 * scale)
      ..lineTo(hc.dx - 1.5 * scale, hc.dy - 25 * scale)
      ..lineTo(hc.dx + 1.5 * scale, hc.dy - 25 * scale)
      ..lineTo(hc.dx + 2.5 * scale, hc.dy + 6 * scale)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0x66FFFFFF));

    // C. Wide Safety Brim (নিরাপত্তা সান-পিক কার্ভ)
    final brim = Path()
      ..moveTo(hc.dx - 29 * scale, hc.dy + 6 * scale)
      ..quadraticBezierTo(hc.dx, hc.dy + 14 * scale, hc.dx + 29 * scale, hc.dy + 6 * scale)
      ..quadraticBezierTo(hc.dx, hc.dy + 9 * scale, hc.dx - 29 * scale, hc.dy + 6 * scale)
      ..close();
    canvas.drawPath(
      brim,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Color(0xFFD97706), Color(0xFFFFFBE8), Color(0xFFD97706)],
        ).createShader(Rect.fromLTWH(hc.dx - 29 * scale, hc.dy + 5 * scale, 58 * scale, 10 * scale)),
    );

    // Under-brim dark shadow
    final underBrim = Path()
      ..moveTo(hc.dx - 25 * scale, hc.dy + 8 * scale)
      ..quadraticBezierTo(hc.dx, hc.dy + 13 * scale, hc.dx + 25 * scale, hc.dy + 8 * scale)
      ..lineTo(hc.dx + 24 * scale, hc.dy + 10 * scale)
      ..quadraticBezierTo(hc.dx, hc.dy + 15 * scale, hc.dx - 24 * scale, hc.dy + 10 * scale)
      ..close();
    canvas.drawPath(underBrim, Paint()..color = const Color(0xAA3B1E05));

    // D. Chin-Strap (চিবুক বন্ধনী - জিরো টলারেন্সের প্রতীক)
    final strapPaint = Paint()
      ..color = const Color(0xFF451A03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;

    final strapLeft = Path()
      ..moveTo(hc.dx - 18 * scale, hc.dy + 9 * scale)
      ..quadraticBezierTo(hc.dx - 12 * scale, hc.dy + 17 * scale, hc.dx - 2 * scale, hc.dy + 20 * scale);
    canvas.drawPath(strapLeft, strapPaint);

    final strapRight = Path()
      ..moveTo(hc.dx + 18 * scale, hc.dy + 9 * scale)
      ..quadraticBezierTo(hc.dx + 12 * scale, hc.dy + 17 * scale, hc.dx + 2 * scale, hc.dy + 20 * scale);
    canvas.drawPath(strapRight, strapPaint);

    // Secure Chin-Strap Clasp/Buckle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(hc.dx, hc.dy + 20 * scale), width: 7 * scale, height: 4.5 * scale),
        Radius.circular(1.5 * scale),
      ),
      Paint()..color = const Color(0xFFFDE68A),
    );

    // E. Front Shield Insignia (Crown Badge with grounded spark)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(hc.dx, hc.dy - 7 * scale), width: 10 * scale, height: 11 * scale),
        Radius.circular(2 * scale),
      ),
      Paint()..color = const Color(0xFF451A03),
    );
    // Micro golden star / zero on helmet
    canvas.drawCircle(Offset(hc.dx, hc.dy - 7 * scale), 2.2 * scale, Paint()..color = const Color(0xFFFDE68A));
  }

  @override
  bool shouldRepaint(covariant _HelmetAuraPainter old) => old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// ৩-ধাপের অভিযান ব্রিফিং মডাল (3-Card Mission Briefing Dialog)
// ─────────────────────────────────────────────────────────────────────────────

class _MissionBriefingDialog extends StatefulWidget {
  final VoidCallback onStart;
  const _MissionBriefingDialog({required this.onStart});

  @override
  State<_MissionBriefingDialog> createState() => _MissionBriefingDialogState();
}

class _MissionBriefingDialogState extends State<_MissionBriefingDialog> {
  final _pageController = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1B2E), Color(0xFF08101C)],
          ),
          border: Border.all(color: const Color(0x66F59E0B), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 10)),
            BoxShadow(color: Color(0x33F59E0B), blurRadius: 20, spreadRadius: 1),
          ],
        ),
        child: Column(
          children: [
            // Top Indicator Dots
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = _page == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: active ? const Color(0xFFFBBF24) : const Color(0x33FBBF24),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                ],
              ),
            ),
            // Bottom Action Bar (Clean Arrow Navigation)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  if (_page > 0)
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x331E293B),
                          border: Border.all(color: const Color(0x4464748B)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 22, color: Color(0xFFCBD5E1)),
                      ),
                    )
                  else
                    const SizedBox(width: 44, height: 44),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_page < 2) {
                        HapticFeedback.lightImpact();
                        unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5));
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        HapticFeedback.heavyImpact();
                        unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.7));
                        Navigator.of(context).pop();
                        widget.onStart();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55F59E0B), blurRadius: 14, offset: Offset(0, 4)),
                        ],
                        border: Border.all(color: const Color(0xFFFFFBE8), width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: Color(0xFF451A03),
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

  Widget _buildSlide1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _LifeHelmetAuraBadge(size: 82),
          const SizedBox(height: 16),
          Text(
            'শূন্য মৃত্যু অভিযান',
            textAlign: TextAlign.center,
            style: zlText(22, weight: FontWeight.w900, color: const Color(0xFFFFF6D8)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x33EF4444),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0x88EF4444)),
            ),
            child: Text(
              '⚠️ ১টি ভুল = ১টি মৃত্যুঝুঁকি',
              style: zlText(12, weight: FontWeight.w800, color: const Color(0xFFFCA5A5)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'বিদ্যুতের লাইনে কোনো "ছোট ভুল" নেই। প্রতিটি অসাবধানতা সরাসরি প্রাণঘাতী বিপদ ডেকে আনে। ধাপে ধাপে সঠিক সুরক্ষা ও নিয়ম মানাই মৃত্যুহীন পথের একমাত্র পাথেয়।',
            textAlign: TextAlign.center,
            style: zlText(13.5, height: 1.45, color: const Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'কাজের ৩টি হিসেব',
            textAlign: TextAlign.center,
            style: zlText(20, weight: FontWeight.w900, color: const Color(0xFFFFF6D8)),
          ),
          const SizedBox(height: 4),
          Text(
            'সব লেভেলের মোট হিসাব জমা থাকবে',
            textAlign: TextAlign.center,
            style: zlText(12, color: const Color(0xFFFDE68A)),
          ),
          const SizedBox(height: 16),
          _metricRow(
            icon: Icons.stars_rounded,
            color: const Color(0xFFFBBF24),
            title: 'মোট স্কোর',
            desc: 'প্রতি লেভেলে সঠিক কাজের পয়েন্ট। ডিভাইসের মেমরিতে জমা থাকবে।',
          ),
          const SizedBox(height: 10),
          _metricRow(
            icon: Icons.shield_rounded,
            color: const Color(0xFF34D399),
            title: 'মৃত্যুঝুঁকি (০ লক্ষ্য)',
            desc: 'ভুল হলেই বাড়বে। আপনার লক্ষ্য: প্রতিটি লেভেলে ০ মৃত্যুঝুঁকি রাখা।',
          ),
          const SizedBox(height: 10),
          _metricRow(
            icon: Icons.timer_outlined,
            color: const Color(0xFF38BDF8),
            title: 'মোট সময়',
            desc: 'কাজে অতিবাহিত মোট সময়। তাড়াহুড়ো নয়, স্থির ও নিরাপদ কাজ।',
          ),
        ],
      ),
    );
  }

  Widget _metricRow({required IconData icon, required Color color, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x33060E18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: zlText(13, weight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(desc, style: zlText(11.5, height: 1.3, color: const Color(0xFFCBD5E1))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x2210B981),
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.verified_user_rounded, size: 38, color: Color(0xFF34D399)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'লাইনম্যানের শপথ',
                textAlign: TextAlign.center,
                style: zlText(21, weight: FontWeight.w900, color: const Color(0xFFFFF6D8)),
              ),
              const SizedBox(height: 12),
              _pledgeItem('সুরক্ষায় কোনো আপস নয় — শতভাগ পিপিই'),
              const SizedBox(height: 8),
              _pledgeItem('ভুল না করে ০ মৃত্যুঝুঁকি অক্ষুণ্ণ রাখব'),
              const SizedBox(height: 8),
              _pledgeItem('নিরাপদে কাজ সেরে পরিবারের কাছে ফিরব'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pledgeItem(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x3310B981),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x4434D399)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF34D399)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: zlText(12.5, weight: FontWeight.w700, color: const Color(0xFFF1F5F9))),
          ),
        ],
      ),
    );
  }
}

class _CoverBoard extends StatefulWidget {
  final VoidCallback onOpen;
  const _CoverBoard({required this.onOpen});

  @override
  State<_CoverBoard> createState() => _CoverBoardState();
}

class _CoverBoardState extends State<_CoverBoard> with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _intro;
  late final AnimationController _ctaPulse;
  late final AnimationController _exit;
  var _isExiting = false;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _ctaPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))..forward();
    _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.85));
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _intro.dispose();
    _ctaPulse.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: AnimatedBuilder(
        animation: Listenable.merge([_glow, _intro, _ctaPulse, _exit]),
        builder: (context, _) {
          final pulse = 0.55 + (0.45 * _glow.value);
          final introVal = Curves.easeOutBack.transform(_intro.value.clamp(0.0, 1.0));
          final ctaPulseVal = 1.0 + (math.sin(_ctaPulse.value * math.pi) * 0.04);
          final exitVal = Curves.easeInOutCubic.transform(_exit.value);

          return Transform.translate(
            offset: Offset(0, 90 * exitVal),
            child: Opacity(
              opacity: (1.0 - exitVal).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.0 - (0.10 * exitVal),
                child: Column(
                  children: [
                    const Spacer(),
                    // Hero Badge: জীবনের শিরস্ত্রাণ ও স্বর্ণবলয়
                    Transform.scale(
                      scale: introVal,
                      child: _LifeHelmetAuraBadge(pulse: pulse, size: 104),
                    ),
                    const SizedBox(height: 24),
                    // Game Title with golden bloom
                    Transform.translate(
                      offset: Offset(0, 24 * (1.0 - _intro.value)),
                      child: Opacity(
                        opacity: _intro.value.clamp(0.0, 1.0),
                        child: Column(
                          children: [
                            Text(
                              'মৃত্যুহীন পথ',
                              textAlign: TextAlign.center,
                              style: zlText(38, weight: FontWeight.w900, height: 1.25, color: const Color(0xFFFFF6D8)).copyWith(
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(color: Color.fromRGBO(251, 191, 36, 0.9 * pulse), blurRadius: 22),
                                  Shadow(color: Color.fromRGBO(255, 247, 214, 0.65 * pulse), blurRadius: 42),
                                  const Shadow(color: Color(0x99000000), offset: Offset(0, 4), blurRadius: 10),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0x33F59E0B),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: Color.fromRGBO(251, 191, 36, 0.4 * pulse), width: 1.0),
                              ),
                              child: Text(
                                'শূন্য দুর্ঘটনা অভিযান • জিরো টলারেন্স',
                                textAlign: TextAlign.center,
                                style: zlText(13, weight: FontWeight.w700, color: const Color(0xFFFDE68A)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'ধাপে ধাপে সঠিক সুরক্ষায় বাঁচবে জীবন',
                              textAlign: TextAlign.center,
                              style: zlText(14.5, weight: FontWeight.w500, color: const Color(0xFFD6CBB2)).copyWith(
                                shadows: const [Shadow(color: Color(0x88000000), blurRadius: 8)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Gamified Action Button
                    Transform.scale(
                      scale: ctaPulseVal * introVal,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.85));
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierColor: const Color(0xF2040A14),
                            builder: (ctx) => BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: _MissionBriefingDialog(
                                onStart: () {
                                  if (_isExiting) return;
                                  _isExiting = true;
                                  _exit.forward().then((_) {
                                    if (mounted) widget.onOpen();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 290),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(245, 158, 11, 0.45 * pulse),
                                offset: const Offset(0, 8),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                              const BoxShadow(
                                color: Color(0x55000000),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFFFFBEB), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'অভিযান শুরু করুন',
                                style: zlText(18, weight: FontWeight.w800, color: const Color(0xFF451A03)),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 24, color: Color(0xFF451A03)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  const _PaperCard({required this.child, this.onTap, this.onTapDown});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6E9C8),
      elevation: 6,
      shadowColor: const Color(0x88000000),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
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

class _RoadBoard extends StatefulWidget {
  final DutySlipEngine engine;
  final void Function(int index) onOpen;
  const _RoadBoard({required this.engine, required this.onOpen});

  @override
  State<_RoadBoard> createState() => _RoadBoardState();
}

class _RoadBoardState extends State<_RoadBoard> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _drift;

  static const _itemH = 82.0;
  static const _groundH = 150.0;
  static const _sky = 10;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 48))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pinNext(initial: true));
  }

  @override
  void didUpdateWidget(covariant _RoadBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine.unlocked != widget.engine.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pinNext());
    }
  }

  void _pinNext({bool initial = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final focus = dsAllLevelsOpen ? 0 : widget.engine.unlocked;
    final target = (_groundH + focus * _itemH) - (view * 0.28);
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent);
    if (initial) {
      // Cinematic ascension from base to the active level rung
      _scroll.jumpTo(0.0);
      _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final live = dsLevels.length;
    final total = 1 + live + _sky;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (_, _) => AnimatedBuilder(
                animation: _scroll,
                builder: (_, _) {
                  final scroll = _scroll.hasClients ? _scroll.offset : 0.0;
                  return CustomPaint(
                    painter: _SkyMotionPainter(time: _drift.value, scroll: scroll),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ),
        Column(
          children: [
            // Center-aligned Ladder Header (Clean title and floating Score Chip)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Center-aligned title without logo
                  Text(
                    'মৃত্যুহীন পথ',
                    textAlign: TextAlign.center,
                    style: zlText(18, weight: FontWeight.w900, color: const Color(0xFFFFF6D8)).copyWith(
                      letterSpacing: 0.8,
                      shadows: const [
                        Shadow(color: Color(0xCCF59E0B), blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Score & Telemetry Chip just below it (plenty of room for high scores)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC060E18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0x33FBBF24)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Score
                        const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFFBBF24)),
                        const SizedBox(width: 4),
                        Text(
                          _bnNum(e.totalCumulativeScore),
                          style: zlText(12, weight: FontWeight.w800, color: const Color(0xFFFFFBE8)),
                        ),
                        Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 1, height: 12, color: const Color(0x22FFFFFF)),
                        // Danger Count (Zero Loss Focus)
                        Icon(
                          e.totalCumulativeDanger == 0 ? Icons.shield_rounded : Icons.warning_amber_rounded,
                          size: 14,
                          color: e.totalCumulativeDanger == 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _bnNum(e.totalCumulativeDanger),
                          style: zlText(
                            12,
                            weight: FontWeight.w800,
                            color: e.totalCumulativeDanger == 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 1, height: 12, color: const Color(0x22FFFFFF)),
                        // Time
                        const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        Text(
                          e.formatClock(e.totalCumulativeSeconds),
                          style: zlText(11.5, weight: FontWeight.w700, color: const Color(0xFFE2E8F0)),
                        ),
                        const SizedBox(width: 8),
                        // Info Button to re-open briefing dialog
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showDialog(
                              context: context,
                              barrierColor: const Color(0xF2040A14),
                              builder: (_) => BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: _MissionBriefingDialog(onStart: () {}),
                              ),
                            );
                          },
                          child: const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xCCFBBF24)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: EdgeInsets.zero,
                itemCount: total,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return const SizedBox(
                      height: _groundH,
                      child: IgnorePointer(child: CustomPaint(painter: _GroundPainter(), size: Size.infinite)),
                    );
                  }
                  final liveI = i - 1;
                  late final Widget orb;
                  if (liveI >= live) {
                    orb = _LevelOrb(
                      number: liveI + 1,
                      next: false,
                      locked: true,
                      rank: null,
                      field: false,
                      bestSec: null,
                    );
                  } else {
                    final spec = dsLevels[liveI];
                    final locked = !dsAllLevelsOpen && liveI > e.unlocked;
                    final next = !dsAllLevelsOpen && liveI == e.unlocked;
                    final rank = e.bestRank[liveI];
                    orb = _LevelOrb(
                      number: spec.number,
                      next: next,
                      locked: locked,
                      rank: rank,
                      field: spec.isField,
                      bestSec: e.bestDarunSec[liveI],
                      onTap: locked ? null : () => widget.onOpen(liveI),
                    );
                  }
                  return SizedBox(
                    height: _itemH,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _BambooRungPainter(index: liveI, sky: liveI >= live),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                        orb,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkyMotionPainter extends CustomPainter {
  final double time;
  final double scroll;
  const _SkyMotionPainter({required this.time, required this.scroll});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rise = (scroll / 1200.0).clamp(0.0, 1.0);

    // 1. Dynamic Night Sky Dome Gradient (deepens to cosmic indigo at high altitudes)
    final rect = Offset.zero & size;
    final topSky = Color.lerp(const Color(0xFF040814), const Color(0xFF01040A), rise)!;
    final midSky = Color.lerp(const Color(0xFF091629), const Color(0xFF050E1A), rise)!;
    final lowSky = Color.lerp(const Color(0xFF142C3F), const Color(0xFF0D2132), rise)!;
    final rimSky = Color.lerp(const Color(0xFF203F54), const Color(0xFF2E4E64), rise)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topSky, midSky, lowSky, rimSky],
          stops: const [0.0, 0.35, 0.68, 1.0],
        ).createShader(rect),
    );

    // 2. Deep Space Stars with Multi-Frequency Twinkle
    _paintStars(canvas, w, h, scroll, time);

    // 3. Volumetric Moon & Luminous Atmosphere
    final moon = Offset(w * 0.82, h * 0.12 + scroll * 0.035);
    // Outer atmospheric glow
    canvas.drawCircle(
      moon,
      64,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x20FFF4C2), Color(0x00FFF4C2)],
        ).createShader(Rect.fromCircle(center: moon, radius: 64)),
    );
    // Inner halo
    canvas.drawCircle(moon, 28, Paint()..color = const Color(0x28FFF6D0));
    // Moon disc
    canvas.drawCircle(moon, 14, Paint()..color = const Color(0xFFFFFBE0));
    // Soft crescent shadow for natural lunar curvature
    canvas.drawCircle(moon + const Offset(4, -3), 12, Paint()..color = const Color(0x18000000));

    // 4. Cloud Tier 1: High-Altitude Cirrus Wisps (silver, translucent, slow drifting)
    _paintCirrusClouds(canvas, w, h, time, scroll);

    // 5. Parallax Horizon Calculation:
    // As the lineman climbs higher (scroll up), the horizon descends downwards,
    // revealing a vast panoramic perspective of the city below.
    final horizon = h * 0.58 + (scroll * 0.11);

    // 6. City Layer 1: Distant Mountain Contours & High-Voltage Transmission Pylons
    _paintDistantMountainsAndTowers(canvas, w, horizon, scroll, time);

    // 7. Ambient City Light Dome (warm sodium glow rising into the sky from the metropolis)
    _paintCityLightDome(canvas, w, horizon, rise);

    // 8. City Layer 2: Megacity High-Rise Skyline (High towers, spires, illuminated window matrices)
    _paintMegacitySkyline(canvas, w, horizon, rise, time, scroll);

    // 9. City Layer 3: Mid-Distance Commercial District & Neon Billboards
    _paintCommercialDistrict(canvas, w, horizon, rise, time, scroll);

    // 10. Cloud Tier 2: Mid-Altitude Volumetric Cumulus Cloud Banks (3D billows with moonlit rims)
    _paintCumulusClouds(canvas, w, h, time, scroll);

    // 11. City Layer 4: Near Substation & Distribution Grid (Poles, catenary wires, sodium streetlights)
    _paintForegroundGrid(canvas, w, horizon, rise, time, scroll);

    // 12. Cloud Tier 3: Low Atmospheric Ground Fog & Electrical Haze
    _paintGroundMist(canvas, w, horizon, time, scroll);
  }

  @override
  bool shouldRepaint(covariant _SkyMotionPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.scroll != scroll;
}

void _paintStars(Canvas canvas, double w, double h, double scroll, double time) {
  final rng = math.Random(42);
  final starPaint = Paint()..color = const Color(0x88FFF8E1);
  for (var i = 0; i < 28; i++) {
    final x = rng.nextDouble() * w;
    final y = (rng.nextDouble() * h * 0.44 + scroll * 0.02) % (h * 0.52);
    final twinkle = (math.sin((time * math.pi * 2 * 1.8) + (i * 1.7)) * 0.5 + 0.5);
    final radius = rng.nextDouble() * 1.1 + 0.35;
    final alpha = (0.25 + 0.65 * twinkle).clamp(0.0, 0.95);
    canvas.drawCircle(
      Offset(x, y),
      radius,
      starPaint..color = Color.fromRGBO(255, 248, 225, alpha),
    );
    // Subtle sparkle cross on 3 prominent stars
    if (i % 9 == 0 && twinkle > 0.7) {
      final crossPaint = Paint()
        ..color = Color.fromRGBO(255, 248, 225, (twinkle - 0.7) * 2.2)
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(x - 3.5, y), Offset(x + 3.5, y), crossPaint);
      canvas.drawLine(Offset(x, y - 3.5), Offset(x, y + 3.5), crossPaint);
    }
  }
}

void _paintCirrusClouds(Canvas canvas, double w, double h, double time, double scroll) {
  final span = w + 260;
  // Cloud 1: Upper wisps passing near the moon
  final x1 = ((time * 0.035 * span) % span) - 80;
  final y1 = h * 0.09 + scroll * 0.025 + math.sin(time * math.pi * 2 * 0.5) * 3;
  _drawCirrusWisp(canvas, Offset(x1, y1), 1.4);

  // Cloud 2: Secondary streamer
  final x2 = (((time * 0.05 * span) + (w * 0.55)) % span) - 80;
  final y2 = h * 0.16 + scroll * 0.035 + math.cos(time * math.pi * 2 * 0.6) * 3;
  _drawCirrusWisp(canvas, Offset(x2, y2), 1.15);
}

void _drawCirrusWisp(Canvas canvas, Offset o, double s) {
  final body = Paint()..color = const Color(0x18D8E4F2);
  final rim = Paint()..color = const Color(0x14FFFDEB);
  canvas.drawOval(Rect.fromCenter(center: o, width: 180 * s, height: 18 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-40 * s, -3 * s), width: 110 * s, height: 14 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(45 * s, 2 * s), width: 90 * s, height: 12 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-10 * s, -5 * s), width: 80 * s, height: 8 * s), rim);
}

void _paintDistantMountainsAndTowers(Canvas canvas, double w, double horizon, double scroll, double time) {
  final baseY = horizon - 34 + (scroll * 0.03);
  final ridge = Path()..moveTo(0, baseY);
  // Gentle rolling mountain contour
  ridge.quadraticBezierTo(w * 0.22, baseY - 24, w * 0.44, baseY - 8);
  ridge.quadraticBezierTo(w * 0.70, baseY - 28, w, baseY - 12);
  ridge.lineTo(w, baseY + 60);
  ridge.lineTo(0, baseY + 60);
  ridge.close();

  canvas.drawPath(ridge, Paint()..color = const Color(0xFF070E1A));

  // High-Voltage 400kV Lattice Transmission Towers on the ridge line
  final towerPositions = [w * 0.18, w * 0.54, w * 0.86];
  for (var i = 0; i < towerPositions.length; i++) {
    final tx = towerPositions[i];
    final ty = baseY - (i == 0 ? 18 : i == 1 ? 10 : 22);
    _drawTransmissionTower(canvas, tx, ty, time, i);
  }
}

void _drawTransmissionTower(Canvas canvas, double tx, double ty, double time, int id) {
  final p = Paint()
    ..color = const Color(0xFF0A1626)
    ..strokeWidth = 1.1;

  // Tapered tower body
  canvas.drawLine(Offset(tx - 5, ty + 26), Offset(tx - 1.5, ty), p);
  canvas.drawLine(Offset(tx + 5, ty + 26), Offset(tx + 1.5, ty), p);
  // Crossarms
  canvas.drawLine(Offset(tx - 11, ty + 7), Offset(tx + 11, ty + 7), p);
  canvas.drawLine(Offset(tx - 8, ty + 15), Offset(tx + 8, ty + 15), p);
  // Spire peak
  canvas.drawLine(Offset(tx, ty), Offset(tx, ty - 5), p);

  // Red blinking aviation safety beacon on top of the transmission tower
  final blink = math.sin((time * math.pi * 3.2) + (id * 2.1)) > 0.35;
  final beaconColor = blink ? const Color(0xFFFF2828) : const Color(0x22FF2828);
  canvas.drawCircle(Offset(tx, ty - 5.5), 1.8, Paint()..color = beaconColor);
  if (blink) {
    canvas.drawCircle(Offset(tx, ty - 5.5), 5.0, Paint()..color = const Color(0x33FF2828));
  }
}

void _paintCityLightDome(Canvas canvas, double w, double horizon, double rise) {
  if (rise <= 0.02) return;
  final domeRect = Rect.fromLTWH(0, horizon - 80, w, 110);
  canvas.drawRect(
    domeRect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.fromRGBO(245, 158, 11, 0.22 * rise),
          Color.fromRGBO(56, 189, 248, 0.08 * rise),
          const Color(0x00000000),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(domeRect),
  );
}

void _paintMegacitySkyline(Canvas canvas, double w, double horizon, double rise, double time, double scroll) {
  final baseY = horizon - 12 + (scroll * 0.065);
  final rng = math.Random(107);
  var x = -12.0;
  final bodyPaint = Paint()..color = const Color(0xFF0A1526);

  while (x < w + 28) {
    final bw = 18.0 + rng.nextDouble() * 32.0;
    // As lineman climbs higher (rise increases), towers appear taller and deeper
    final bh = (32.0 + rng.nextDouble() * 64.0) * (0.80 + (rise * 0.45));
    final hasSpire = rng.nextDouble() > 0.65;
    final stepped = rng.nextDouble() > 0.70;

    // Building silhouette
    if (stepped) {
      // Stepped crown skyscraper
      final stepW = bw * 0.65;
      final stepH = bh * 0.25;
      canvas.drawRect(Rect.fromLTWH(x, baseY - bh + stepH, bw, bh - stepH + 40), bodyPaint);
      canvas.drawRect(Rect.fromLTWH(x + (bw - stepW) / 2, baseY - bh, stepW, stepH), bodyPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(x, baseY - bh, bw, bh + 40), bodyPaint);
    }

    // Antenna spire with strobe
    if (hasSpire) {
      final sx = x + bw / 2;
      final sy = baseY - bh;
      canvas.drawLine(Offset(sx, sy), Offset(sx, sy - 14), Paint()..color = const Color(0xFF0A1526)..strokeWidth = 1.2);
      final strobe = math.sin((time * math.pi * 4.0) + x) > 0.55;
      canvas.drawCircle(Offset(sx, sy - 14), 1.4, Paint()..color = strobe ? const Color(0xFFFF5252) : const Color(0x18FF5252));
    }

    // High-Density Window Matrices
    final cols = (bw / 5.2).floor().clamp(1, 6);
    final baseRows = (bh / 6.8).floor().clamp(2, 14);
    // As player climbs, more rows of windows are revealed downwards!
    final visibleRows = (baseRows + (rise * 4).toInt()).clamp(2, 16);

    for (var r = 0; r < visibleRows; r++) {
      for (var c = 0; c < cols; c++) {
        final seedVal = rng.nextDouble();
        if (seedVal > (0.18 + rise * 0.68)) continue;

        // Organic city pulse and flicker
        final flicker = (math.sin((time * math.pi * 2 * 2.1) + (r * 0.7) + (c * 1.3) + (x * 0.2)) * 0.5 + 0.5);
        final a = ((0.15 + (rise * 0.75)) * (0.45 + 0.55 * flicker)).clamp(0.0, 0.94);

        // Curated window palette: warm amber, office white, cyan
        late final Color winColor;
        if (seedVal < 0.08) {
          winColor = Color.fromRGBO(56, 189, 248, a); // Cyan
        } else if (seedVal < 0.22) {
          winColor = Color.fromRGBO(241, 245, 249, a); // Office white
        } else {
          winColor = Color.fromRGBO(255, 214, 120, a); // Warm sodium amber
        }

        canvas.drawRect(
          Rect.fromLTWH(x + 2.4 + (c * 4.8), baseY - bh + 4 + (r * 6.2), 2.2, 3.2),
          Paint()..color = winColor,
        );
      }
    }
    x += bw + 3.0 + rng.nextDouble() * 6.0;
  }
}

void _paintCommercialDistrict(Canvas canvas, double w, double horizon, double rise, double time, double scroll) {
  final baseY = horizon + 16 + (scroll * 0.11);
  final rng = math.Random(219);
  var x = -8.0;
  final bodyPaint = Paint()..color = const Color(0xFF0E1F33);

  while (x < w + 24) {
    final bw = 24.0 + rng.nextDouble() * 38.0;
    final bh = (22.0 + rng.nextDouble() * 45.0) * (0.85 + (rise * 0.35));
    canvas.drawRect(Rect.fromLTWH(x, baseY - bh, bw, bh + 40), bodyPaint);

    // Rooftop water tank or AC unit
    if (rng.nextBool()) {
      final wx = x + 4 + rng.nextDouble() * (bw - 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(wx, baseY - bh - 8, 9, 8), const Radius.circular(2)),
        Paint()..color = const Color(0xFF0B1726),
      );
    }

    // Glowing Neon Signs / Billboards on commercial roofs
    if (rng.nextDouble() > 0.72) {
      final neonX = x + 4.0;
      final neonY = baseY - bh + 4.0;
      final neonColor = rng.nextBool() ? const Color(0xFFF43F5E) : const Color(0xFFFBBF24);
      final neonGlow = 0.55 + 0.45 * math.sin((time * math.pi * 3.5) + x);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(neonX, neonY, 14, 4), const Radius.circular(1)),
        Paint()..color = neonColor.withValues(alpha: neonGlow),
      );
    }

    // Windows
    final cols = (bw / 6.5).floor().clamp(1, 5);
    final rows = (bh / 8.5).floor().clamp(1, 6);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (rng.nextDouble() > (0.25 + rise * 0.65)) continue;
        final a = (0.20 + (rise * 0.72)).clamp(0.0, 0.90);
        canvas.drawRect(
          Rect.fromLTWH(x + 3.0 + (c * 6.2), baseY - bh + 9 + (r * 7.5), 2.8, 3.8),
          Paint()..color = Color.fromRGBO(255, 224, 138, a),
        );
      }
    }
    x += bw + 4.0 + rng.nextDouble() * 8.0;
  }
}

void _paintCumulusClouds(Canvas canvas, double w, double h, double time, double scroll) {
  final span = w + 240;
  // Cloud Specs spanning mid-altitudes
  const specs = [
    _CumulusSpec(y: 0.22, speed: 0.065, scale: 1.15, parallax: 0.065, phase: 0.3),
    _CumulusSpec(y: 0.29, speed: 0.085, scale: 0.92, parallax: 0.075, phase: 1.8),
    _CumulusSpec(y: 0.36, speed: 0.055, scale: 1.25, parallax: 0.085, phase: 2.7),
    _CumulusSpec(y: 0.43, speed: 0.095, scale: 0.85, parallax: 0.095, phase: 0.9),
  ];

  for (var i = 0; i < specs.length; i++) {
    final c = specs[i];
    var x = ((time * c.speed * span) + (i * w * 0.32)) % span;
    x -= 90;
    final y = (h * c.y) + (scroll * c.parallax) + (math.sin((time * math.pi * 2) + c.phase) * 4);
    if (y > h * 0.52) continue;
    _drawVolumetricCloud(canvas, Offset(x, y), c.scale);
  }
}

class _CumulusSpec {
  final double y;
  final double speed;
  final double scale;
  final double parallax;
  final double phase;
  const _CumulusSpec({
    required this.y,
    required this.speed,
    required this.scale,
    required this.parallax,
    required this.phase,
  });
}

void _drawVolumetricCloud(Canvas canvas, Offset o, double s) {
  // Volumetric mass with shaded base and moonlit top rim
  final body = Paint()..color = const Color(0x3218283E);
  final core = Paint()..color = const Color(0x2820354E);
  final rim = Paint()..color = const Color(0x28E2E8F0);
  final moonHighlight = Paint()..color = const Color(0x1EFFF8DB);

  // Darker underside billows
  canvas.drawOval(Rect.fromCenter(center: o, width: 130 * s, height: 32 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-38 * s, -4 * s), width: 72 * s, height: 28 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(42 * s, -6 * s), width: 66 * s, height: 26 * s), body);

  // Volumetric core
  canvas.drawOval(Rect.fromCenter(center: o + Offset(4 * s, -12 * s), width: 56 * s, height: 24 * s), core);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-18 * s, -14 * s), width: 44 * s, height: 22 * s), core);

  // Moonlit silver rim highlights (facing moon on top-right)
  canvas.drawOval(Rect.fromCenter(center: o + Offset(6 * s, -16 * s), width: 46 * s, height: 18 * s), rim);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-16 * s, -17 * s), width: 36 * s, height: 15 * s), moonHighlight);
}

void _paintForegroundGrid(Canvas canvas, double w, double horizon, double rise, double time, double scroll) {
  final baseY = horizon + 48 + (scroll * 0.19);
  final polePaint = Paint()
    ..color = const Color(0xFF091422)
    ..strokeWidth = 2.2;
  final wirePaint = Paint()
    ..color = const Color(0x88091422)
    ..strokeWidth = 0.9
    ..style = PaintingStyle.stroke;

  // 3 utility distribution poles with crossarms
  final poleXs = [w * 0.12, w * 0.50, w * 0.88];
  for (var i = 0; i < poleXs.length; i++) {
    final px = poleXs[i];
    final py = baseY - 48;
    // Main pole
    canvas.drawLine(Offset(px, baseY + 30), Offset(px, py), polePaint);
    // 3-Phase crossarm
    canvas.drawLine(Offset(px - 14, py + 8), Offset(px + 14, py + 8), polePaint..strokeWidth = 1.8);
    // Pin insulators
    canvas.drawCircle(Offset(px - 12, py + 6), 1.5, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawCircle(Offset(px, py + 6), 1.5, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawCircle(Offset(px + 12, py + 6), 1.5, Paint()..color = const Color(0xFF38BDF8));

    // Sodium Streetlight on pole #1 and #3
    if (i == 0 || i == 2) {
      final lampX = px + (i == 0 ? 12 : -12);
      final lampY = py + 14;
      // Arm
      canvas.drawLine(Offset(px, py + 18), Offset(lampX, lampY), polePaint..strokeWidth = 1.4);
      // Amber LED bulb
      canvas.drawCircle(Offset(lampX, lampY), 2.2, Paint()..color = const Color(0xFFFFB703));

      // Downward conical ambient streetlight cone
      final cone = Path()
        ..moveTo(lampX, lampY)
        ..lineTo(lampX - 22, lampY + 44)
        ..lineTo(lampX + 22, lampY + 44)
        ..close();
      canvas.drawPath(
        cone,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0x38F59E0B), Color(0x00F59E0B)],
          ).createShader(cone.getBounds()),
      );
    }
  }

  // Overhead catenary sagging wires connecting poles
  final wire1 = Path()
    ..moveTo(poleXs[0] - 12, baseY - 42)
    ..quadraticBezierTo((poleXs[0] + poleXs[1]) / 2, baseY - 35, poleXs[1] - 12, baseY - 42)
    ..quadraticBezierTo((poleXs[1] + poleXs[2]) / 2, baseY - 35, poleXs[2] - 12, baseY - 42);
  canvas.drawPath(wire1, wirePaint);

  final wire2 = Path()
    ..moveTo(poleXs[0] + 12, baseY - 40)
    ..quadraticBezierTo((poleXs[0] + poleXs[1]) / 2, baseY - 33, poleXs[1] + 12, baseY - 40)
    ..quadraticBezierTo((poleXs[1] + poleXs[2]) / 2, baseY - 33, poleXs[2] + 12, baseY - 40);
  canvas.drawPath(wire2, wirePaint);
}

void _paintGroundMist(Canvas canvas, double w, double horizon, double time, double scroll) {
  final span = w + 200;
  final x = ((time * 0.12 * span) % span) - 80;
  final y = horizon + 22 + (scroll * 0.16);
  final mist = Paint()..color = const Color(0x168DA4C4);
  canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 220, height: 26), mist);
  canvas.drawOval(Rect.fromCenter(center: Offset(x + 140, y + 8), width: 190, height: 22), mist);
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rich ground soil and grass layer
    final soil = Path()
      ..moveTo(0, h * 0.38)
      ..quadraticBezierTo(w * 0.25, h * 0.32, w * 0.5, h * 0.37)
      ..quadraticBezierTo(w * 0.75, h * 0.44, w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      soil,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF3B5628), Color(0xFF283918), Color(0xFF1E150C)],
        ).createShader(Offset.zero & size),
    );

    // Substation Distribution Cabinet / Transformer Base at bottom left
    final boxRect = Rect.fromLTWH(w * 0.08, h * 0.34, 52, 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF1F2B38),
    );
    // Radiator cooling vents
    final ventPaint = Paint()..color = const Color(0xFF121B24)..strokeWidth = 1.0;
    for (var v = 0; v < 4; v++) {
      canvas.drawLine(Offset(w * 0.08 + 8 + v * 9, h * 0.34 + 6), Offset(w * 0.08 + 8 + v * 9, h * 0.34 + 28), ventPaint);
    }
    // High Voltage Warning Plate ("১১,০০০ ভোল্ট • বিপদ")
    final plateRect = Rect.fromLTWH(w * 0.08 + 10, h * 0.34 + 32, 32, 11);
    canvas.drawRRect(
      RRect.fromRectAndRadius(plateRect, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFFBBF24),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08 + 12, h * 0.34 + 34, 4, 7),
      Paint()..color = const Color(0xFFDC2626),
    );

    // Trees in the background
    _tree(canvas, Offset(w * 0.14, h * 0.16), 0.72);
    _tree(canvas, Offset(w * 0.90, h * 0.13), 0.78);

    // Bamboo Pole Foundations
    final cx = w / 2;
    const gap = 36.0;
    _bambooPole(canvas, cx - gap, 0, h * 0.58, 14, seed: 0);
    _bambooPole(canvas, cx + gap, 0, h * 0.58, 14, seed: 1);
    _bambooRung(canvas, cx, h * 0.22, gap, seed: 0);

    // Foundation support soil mounds
    final mound = Paint()..color = const Color(0xFF4A3420);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - gap, h * 0.59), width: 32, height: 16), mound);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + gap, h * 0.59), width: 32, height: 16), mound);

    // Safety Traffic Cones on the ground
    _drawSafetyCone(canvas, Offset(w * 0.26, h * 0.62));
    _drawSafetyCone(canvas, Offset(w * 0.74, h * 0.64));

    // Wild grass blades
    final rng = math.Random(21);
    final blade = Paint()
      ..color = const Color(0x996B8F3C)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 22; i++) {
      final x = rng.nextDouble() * w;
      final y = h * 0.50 + rng.nextDouble() * h * 0.34;
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + (rng.nextBool() ? 4 : -4), y - 11, x + (rng.nextBool() ? 2 : -2), y - 18);
      canvas.drawPath(path, blade);
    }
    _flower(canvas, Offset(w * 0.22, h * 0.72), const Color(0xFFF472B6), 5);
    _flower(canvas, Offset(w * 0.72, h * 0.68), const Color(0xFFFACC15), 5);
    _flower(canvas, Offset(w * 0.86, h * 0.80), const Color(0xFFF9A8D4), 4.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawSafetyCone(Canvas canvas, Offset base) {
  // Orange cone
  final cone = Path()
    ..moveTo(base.dx - 9, base.dy)
    ..lineTo(base.dx - 2.5, base.dy - 20)
    ..lineTo(base.dx + 2.5, base.dy - 20)
    ..lineTo(base.dx + 9, base.dy)
    ..close();
  canvas.drawPath(cone, Paint()..color = const Color(0xFFEA580C));
  // White reflective stripe
  final stripe = Path()
    ..moveTo(base.dx - 6, base.dy - 7)
    ..lineTo(base.dx - 3.8, base.dy - 13)
    ..lineTo(base.dx + 3.8, base.dy - 13)
    ..lineTo(base.dx + 6, base.dy - 7)
    ..close();
  canvas.drawPath(stripe, Paint()..color = const Color(0xFFF8FAFC));
  // Base plate
  canvas.drawRect(Rect.fromCenter(center: base, width: 22, height: 3.5), Paint()..color = const Color(0xFFEA580C));
}

class _BambooRungPainter extends CustomPainter {
  final int index;
  final bool sky;
  const _BambooRungPainter({required this.index, required this.sky});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const gap = 36.0;

    if (!sky && index < 2) {
      _leaves(canvas, Offset(w * 0.12, h * 0.5), index, left: true, thin: true);
      _leaves(canvas, Offset(w * 0.89, h * 0.48), index + 3, left: false, thin: true);
    }
    // Upright bamboo poles
    _bambooPole(canvas, cx - gap, 0, h, 14, seed: index * 2);
    _bambooPole(canvas, cx + gap, 0, h, 14, seed: index * 2 + 1);

    // Cross rung with authentic jute rope lashings
    _bambooRung(canvas, cx, h / 2, gap, seed: index);
  }

  @override
  bool shouldRepaint(covariant _BambooRungPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.sky != sky;
}

void _bambooPole(Canvas canvas, double x, double top, double bot, double width, {required int seed}) {
  final rect = Rect.fromLTRB(x - width / 2, top, x + width / 2, bot);
  // Natural 3D cylindrical bamboo pole gradient
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(8)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFF4A3510),
          Color(0xFF8B6C24),
          Color(0xFFD8C26E),
          Color(0xFFF2E69E),
          Color(0xFF9E7C2C),
          Color(0xFF3E2B0C),
        ],
        stops: const [0.0, 0.18, 0.38, 0.52, 0.82, 1.0],
      ).createShader(rect),
  );

  // Longitudinal wood grain lines
  final grain = Paint()
    ..color = const Color(0x33452B0C)
    ..strokeWidth = 0.8;
  canvas.drawLine(Offset(x - 2.5, top), Offset(x - 2.5, bot), grain);
  canvas.drawLine(Offset(x + 2.5, top), Offset(x + 2.5, bot), grain);

  // Vertical light reflection
  canvas.drawRRect(
    RRect.fromLTRBR(x - width / 2 + 2.2, top + 2, x - 1.2, bot - 2, const Radius.circular(6)),
    Paint()..color = const Color(0x44FFF8E1),
  );

  // Natural segment node ring in the middle
  final nodeY = (top + bot) / 2;
  // Node collar swelling
  canvas.drawRRect(
    RRect.fromLTRBR(x - width / 2 - 1.8, nodeY - 3.4, x + width / 2 + 1.8, nodeY + 3.4, const Radius.circular(4)),
    Paint()..color = const Color(0xFF6B4E16),
  );
  // Dark nodal joint ring
  canvas.drawLine(
    Offset(x - width / 2 - 1.2, nodeY),
    Offset(x + width / 2 + 1.2, nodeY),
    Paint()
      ..color = const Color(0xFF2C1C07)
      ..strokeWidth = 1.3,
  );
  // Node highlight line
  canvas.drawLine(
    Offset(x - width / 2 - 1.0, nodeY - 1.5),
    Offset(x + width / 2 + 1.0, nodeY - 1.5),
    Paint()
      ..color = const Color(0x66FFF6D8)
      ..strokeWidth = 0.9,
  );
}

void _bambooRung(Canvas canvas, double cx, double y, double gap, {required int seed}) {
  final rect = Rect.fromLTRB(cx - gap - 8, y - 6.5, cx + gap + 8, y + 6.5);
  // Horizontal bamboo rung
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(7)),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8D796), Color(0xFF9E7C2C), Color(0xFF4A3510)],
      ).createShader(rect),
  );
  // Center wooden peg
  canvas.drawCircle(Offset(cx, y), 3.2, Paint()..color = const Color(0xFF5C4316));

  // Authentic criss-cross jute rope bindings on both joint sides
  _drawJuteRopeBinding(canvas, cx - gap, y);
  _drawJuteRopeBinding(canvas, cx + gap, y);
}

void _drawJuteRopeBinding(Canvas canvas, double jx, double jy) {
  final rope = Paint()
    ..color = const Color(0xFF6B4A18)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  final fiber = Paint()
    ..color = const Color(0xFFF2DCA0)
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round;

  // Diagonal criss-cross wraps
  canvas.drawLine(Offset(jx - 7, jy - 7), Offset(jx + 7, jy + 7), rope);
  canvas.drawLine(Offset(jx - 7, jy + 7), Offset(jx + 7, jy - 7), rope);
  canvas.drawLine(Offset(jx - 8, jy), Offset(jx + 8, jy), rope);

  // Fiber highlights
  canvas.drawLine(Offset(jx - 5, jy - 5), Offset(jx + 5, jy + 5), fiber);
  canvas.drawLine(Offset(jx - 6, jy - 1), Offset(jx + 6, jy - 1), fiber);
}

void _tree(Canvas canvas, Offset base, double scale) {
  final trunk = Paint()
    ..color = const Color(0xFF3F2A18)
    ..strokeWidth = 8 * scale
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(base, base + Offset(0, -72 * scale), trunk);
  final leaf = Paint()..color = const Color(0xCC1B4332);
  canvas.drawOval(Rect.fromCenter(center: base + Offset(0, -86 * scale), width: 70 * scale, height: 54 * scale), leaf);
  canvas.drawOval(
    Rect.fromCenter(center: base + Offset(-22 * scale, -70 * scale), width: 48 * scale, height: 38 * scale),
    Paint()..color = const Color(0xBB2D6A4F),
  );
  canvas.drawOval(
    Rect.fromCenter(center: base + Offset(24 * scale, -74 * scale), width: 46 * scale, height: 36 * scale),
    Paint()..color = const Color(0xAA40916C),
  );
}

void _flower(Canvas canvas, Offset c, Color petal, double r) {
  final p = Paint()..color = petal;
  for (var i = 0; i < 5; i++) {
    final a = i * math.pi * 2 / 5;
    canvas.drawCircle(c + Offset(math.cos(a) * r * 0.7, math.sin(a) * r * 0.7), r * 0.48, p);
  }
  canvas.drawCircle(c, r * 0.34, Paint()..color = const Color(0xFFFACC15));
}

void _leaves(Canvas canvas, Offset c, int seed, {required bool left, bool thin = false}) {
  final rng = math.Random(seed + 9);
  final n = thin ? 2 : 3;
  for (var i = 0; i < n; i++) {
    final dx = (left ? -1 : 1) * (8.0 + rng.nextDouble() * 22);
    final dy = (rng.nextDouble() - 0.5) * 28;
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(dx, dy), width: thin ? 26 : 34, height: thin ? 18 : 24),
      Paint()..color = Color.fromARGB(thin ? 90 : 140, 27 + rng.nextInt(40), 90 + rng.nextInt(50), 50),
    );
  }
}

String _formatStampBn(int sec) {
  const d = '০১২৩৪৫৬৭৮৯';
  final mStr = (sec ~/ 60).toString().padLeft(2, '0');
  final sStr = (sec % 60).toString().padLeft(2, '0');
  final mBn = mStr.split('').map((ch) => d[int.parse(ch)]).join();
  final sBn = sStr.split('').map((ch) => d[int.parse(ch)]).join();
  return '$mBn:$sBn';
}

class _LevelOrb extends StatefulWidget {
  final int number;
  final bool next;
  final bool locked;
  final DsLevelRank? rank;
  final bool field;
  final int? bestSec;
  final VoidCallback? onTap;
  const _LevelOrb({
    required this.number,
    required this.next,
    required this.locked,
    required this.rank,
    required this.field,
    this.bestSec,
    this.onTap,
  });

  @override
  State<_LevelOrb> createState() => _LevelOrbState();
}

class _LevelOrbState extends State<_LevelOrb> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.next) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _LevelOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.next && _pulse == null) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    } else if (!widget.next && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  List<Color> get _plateColors {
    if (widget.locked) return const [Color(0xFF5A626E), Color(0xFF383E48), Color(0xFF22262C)];
    if (widget.rank == DsLevelRank.darun) return const [Color(0xFFFDE68A), Color(0xFFD97706), Color(0xFF78350F)];
    if (widget.rank == DsLevelRank.motamuti) return const [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF475569)];
    if (widget.next) return const [Color(0xFFFEF08A), Color(0xFFF59E0B), Color(0xFF92400E)];
    if (widget.field) return const [Color(0xFFCBD5E1), Color(0xFF64748B), Color(0xFF334155)];
    return const [Color(0xFFFDE047), Color(0xFFB45309), Color(0xFF451A03)];
  }

  @override
  Widget build(BuildContext context) {
    final metal = _plateColors;
    final stamp = (widget.locked || widget.bestSec == null)
        ? ''
        : _formatStampBn(widget.bestSec!);

    return AnimatedBuilder(
      animation: _pulse ?? kAlwaysCompleteAnimation,
      builder: (context, _) {
        final pVal = _pulse?.value ?? 0.0;
        final isNext = widget.next;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Floating animated upward chevron indicator for the active climb target
            if (isNext)
              Positioned(
                top: -24 - (4 * pVal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xCC091422),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 0.9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard_double_arrow_up_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(
                        'পরবর্তী',
                        style: zlText(9.5, weight: FontWeight.w800, color: const Color(0xFFFDE68A)),
                      ),
                    ],
                  ),
                ),
              ),

            // Inspection Plate Widget
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 72,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: metal,
                    stops: const [0.0, 0.46, 1.0],
                  ),
                  border: Border.all(
                    color: isNext ? const Color(0xFFFFFBEB) : metal.last,
                    width: isNext ? 1.6 : 1.2,
                  ),
                  boxShadow: [
                    if (isNext) ...[
                      BoxShadow(
                        color: Color.fromRGBO(245, 158, 11, 0.45 + (0.35 * pVal)),
                        blurRadius: 18 + (6 * pVal),
                        spreadRadius: 2 + (2 * pVal),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(56, 189, 248, 0.35 * pVal),
                        blurRadius: 10,
                      ),
                    ] else
                      const BoxShadow(color: Color(0x99000000), offset: Offset(0, 2), blurRadius: 3),
                  ],
                ),
                child: Stack(
                  children: [
                    // Top rim specular highlight
                    Positioned(
                      top: 1.2,
                      left: 3,
                      right: 3,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x66FFFFFF),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Bottom bevel shadow
                    Positioned(
                      bottom: 1.2,
                      left: 4,
                      right: 4,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x44000000),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Corner Rivets
                    const Positioned(left: 4, top: 0, bottom: 0, child: Center(child: _MetalRivet())),
                    const Positioned(right: 4, top: 0, bottom: 0, child: Center(child: _MetalRivet())),

                    // Center Content (Number, Lock, or Stars)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: stamp.isEmpty ? 0 : 7),
                        child: widget.locked
                            ? const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF94A3B8))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _bnNum(widget.number),
                                    style: zlText(16.5, weight: FontWeight.w900, color: const Color(0xFF1C1408)).copyWith(
                                      shadows: const [
                                        Shadow(offset: Offset(0, 1), color: Color(0x55FFFFFF), blurRadius: 0),
                                        Shadow(offset: Offset(0, -0.6), color: Color(0x66000000), blurRadius: 0),
                                      ],
                                    ),
                                  ),
                                  if (widget.rank != null && widget.rank != DsLevelRank.again) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      widget.rank == DsLevelRank.darun ? Icons.stars_rounded : Icons.star_half_rounded,
                                      size: 13,
                                      color: widget.rank == DsLevelRank.darun ? const Color(0xFF78350F) : const Color(0xFF334155),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),

                    if (stamp.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 3,
                        child: Text(
                          stamp,
                          textAlign: TextAlign.center,
                          style: zlText(9, weight: FontWeight.w800, color: const Color(0xCC2A1C0A), height: 1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetalRivet extends StatelessWidget {
  const _MetalRivet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5.5,
      height: 5.5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE4C8), Color(0xFF8A7340), Color(0xFF3F2A10)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 0.6), blurRadius: 0.4),
        ],
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

class _StepThumb extends StatelessWidget {
  final String path;
  final double w;
  final double h;
  final String? badge;
  final Color? badgeColor;
  const _StepThumb({required this.path, this.w = 56, this.h = 56, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x18FFFFFF),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                path,
                width: w,
                height: h,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.image_rounded, color: Color(0x44FFFFFF), size: 20),
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -5,
              left: -5,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF131C2E), width: 2),
                  boxShadow: [BoxShadow(color: (badgeColor ?? const Color(0xFFF59E0B)).withValues(alpha: 0.4), blurRadius: 6)],
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                ),
              ),
            ),
        ],
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
    _insist = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.48, muted: widget.muted));
    Future<void>.delayed(const Duration(milliseconds: 480), () {
      if (!mounted || _said) return;
      _said = true;
      unawaited(widget.onSpeak('আসল কাজ। ২৩ ধাপ। মাঠে তার ছিঁড়ে পড়ে আছে। শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।'));
    });
  }

  void _onTick() {
    for (var i = 0; i < dsJobGroups.length; i++) {
      if (_run.value >= _btnStart(i) && _pinged.add(i)) {
        unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.38, muted: widget.muted));
        HapticFeedback.mediumImpact();
      }
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
      animation: Listenable.merge([_run, _insist]),
      builder: (_, _) {
        final next = _span(_run.value, 0.88, 1.00);
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
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
                  icon: const Icon(Icons.arrow_back_rounded, color: ZlColors.soft),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
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
                          onNext: widget.onNext,
                        )
                      : _page == 1
                          ? _review(plan)
                          : _asolPage(plan, next),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _asolPage(List<DsPlanItem> plan, double next) {
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Center(
            child: group == null
                ? _FloatArrow(reveal: next, onTap: _toReview)
                : _FloatArrow(icon: Icons.arrow_back_rounded, onTap: _closeGroup),
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
    final insist = 1 + 0.03 * _insist.value;
    return Opacity(
      opacity: punch.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - punch.clamp(0.0, 1.0))),
        child: Transform.scale(
          scale: (0.86 + 0.14 * punch.clamp(0.0, 1.2)) * insist,
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
          'আসল কাজ',
          textAlign: TextAlign.center,
          style: zlText(28, weight: FontWeight.w900, height: 1.28, color: const Color(0xFFF6E7B0)).copyWith(
            shadows: const [Shadow(color: Color(0x66C9A227), blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '২৩ ধাপ। মাঠে তার ছিঁড়ে পড়ে আছে।',
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Center(child: _FloatArrow(onTap: _toHint)),
        ),
      ],
    );
  }

  void _toggleGroup(int g) {
    setState(() {
      _openGroup = g;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.48, muted: widget.muted));
    HapticFeedback.mediumImpact();
    unawaited(widget.onSpeak(dsJobGroups[g].title));
  }

  void _closeGroup() {
    if (_openGroup == null) return;
    setState(() {
      _openGroup = null;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.42, muted: widget.muted));
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
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: widget.muted));
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
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    unawaited(widget.onSpeak('শুরু থেকে শেষ পর্যন্ত কাজের ধাপগুলো দেখে নিন।'));
  }

  void _toHint() {
    setState(() {
      _page = 2;
      _openStep = null;
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: widget.muted));
    HapticFeedback.mediumImpact();
    final hint = widget.engine.briefOf().body.trim();
    if (hint.isNotEmpty) unawaited(widget.onSpeak(hint));
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
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.48, muted: widget.muted));
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
    return Stack(
      children: [
        Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: ZlColors.soft),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'লেভেল ${_bnNum(widget.engine.level.number)}',
                    style: zlText(13, weight: FontWeight.w800, color: const Color(0xFFB7A57A)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: const Color(0x55C9A227))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: Container(width: 7, height: 7, color: const Color(0xFFC9A227)),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: const Color(0x55C9A227))),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      brief.title,
                      textAlign: TextAlign.center,
                      style: zlText(28, weight: FontWeight.w900, height: 1.28, color: const Color(0xFFF6E7B0)).copyWith(
                        shadows: const [Shadow(color: Color(0x66C9A227), blurRadius: 12)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 118),
                      child: Image.asset(
                        _dressIntroArt(widget.engine.level.number),
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FloatArrow(
                      onTap: widget.onNext,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
        Positioned(left: 8, bottom: 8, child: DsCoach(mood: DsCoachMood.talk, line: brief.body, bubbleWidth: 210)),
      ],
    );
  }
}

String _dressIntroArt(int level) => switch (level) {
      2 => 'assets/duty_slip/dress/tray_elec_helmet.webp',
      3 => 'assets/duty_slip/dress/tray_rubber_gloves.webp',
      4 => 'assets/duty_slip/dress/tray_harness.webp',
      5 => 'assets/duty_slip/dress/kit_ready.webp',
      6 => 'assets/safety/library/ppe/Lineman_Boot_3.webp',
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
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.48, muted: widget.muted));
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
        unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.42, muted: widget.muted));
        HapticFeedback.mediumImpact();
      }
    }
    if (_run.value >= 0.94 && !_nextCue) {
      _nextCue = true;
      unawaited(ZlFx.cue('sounds/quiz_complete.wav', volume: 0.32, muted: widget.muted));
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    if (_showBody) {
                      setState(() {
                        _showBody = false;
                        _open = null;
                      });
                      return;
                    }
                    widget.onBack();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: ZlColors.soft),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
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
                          onNext: widget.onNext,
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
              ),
            ],
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
      unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: widget.muted));
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
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.5, muted: widget.muted));
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
        Column(
          children: [
            const SizedBox(height: 8),
            Opacity(
              opacity: chip,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - chip)),
                child: Text(
                  'লেভেল ${_bnNum(e.level.number)}',
                  style: zlText(13, weight: FontWeight.w800, color: const Color(0xFFB7A57A)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: line,
              child: Row(
                children: [
                  Expanded(child: Container(height: 1, color: const Color(0x55C9A227))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(width: 7, height: 7, color: const Color(0xFFC9A227)),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: const Color(0x55C9A227))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Opacity(
              opacity: titleIn,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - titleIn)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    brief.title,
                    textAlign: TextAlign.center,
                    style: zlText(28, weight: FontWeight.w900, height: 1.28, color: const Color(0xFFF6E7B0)).copyWith(
                      shadows: const [Shadow(color: Color(0x66C9A227), blurRadius: 12)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
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
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 6,
                    child: Center(child: _FloatArrow(reveal: next, onTap: onNext)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuidePane extends StatelessWidget {
  final String body;
  final double bloom;
  final VoidCallback onNext;
  const _GuidePane({super.key, required this.body, required this.bloom, required this.onNext});

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
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Center(child: _FloatArrow(onTap: onNext)),
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
  final String? mark;
  const _StepCard({required this.item, required this.punch, required this.focused, this.mark});

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
              mark == null ? item.labelBn : '$mark  ${item.labelBn}',
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
                                                  child: Image.asset(
                                                    item.icon,
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
                                              item.labelBn,
                                              textAlign: TextAlign.center,
                                              style: zlText(18, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
                                            ),
                                            if (item.whyBn.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                item.whyBn,
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
  final bool focused;
  const _BriefStamp({required this.label, this.focused = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: focused
              ? const [Color(0xFFFFF3C4), Color(0xFFE0B13A), Color(0xFF8A5A10)]
              : const [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)],
        ),
        border: Border.all(color: focused ? const Color(0xFFF6E7B0) : const Color(0xFF5C4316), width: focused ? 1.4 : 1),
        boxShadow: focused
            ? const [
                BoxShadow(color: Color(0x88FBBF24), blurRadius: 14),
                BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1),
              ]
            : const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 1)],
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

class _SafeHomeWord extends StatelessWidget {
  final int lit;
  const _SafeHomeWord({required this.lit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < dsSafeHome.length; i++) ...[
          if (i == 4) const SizedBox(width: 10),
          Text(
            dsSafeHome[i].letter,
            style: zlText(
              22,
              weight: FontWeight.w900,
              color: i < lit ? ZlColors.amber : ZlColors.soft.withValues(alpha: 0.35),
            ),
          ),
        ],
      ],
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
            engine.level.isLetters ? engine.currentDeck[i].labelBn : '${_bnNum(i + 1)}  ${engine.currentDeck[i].labelBn}',
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

class _ArrangeBoard extends StatefulWidget {
  final DutySlipEngine engine;
  final void Function(String id, Offset global) onPlan;
  const _ArrangeBoard({required this.engine, required this.onPlan});

  @override
  State<_ArrangeBoard> createState() => _ArrangeBoardState();
}

class _ArrangeBoardState extends State<_ArrangeBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _riffle;

  @override
  void initState() {
    super.initState();
    _riffle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  }

  @override
  void dispose() {
    _riffle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final pool = e.planPool;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Column(
        children: [
          _PickedStrip(engine: e),
          const SizedBox(height: 8),
          _DealDeck(animation: _riffle),
          Expanded(
            child: ListView.separated(
              clipBehavior: Clip.none,
              itemCount: pool.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (_, i) {
                final p = pool[i];
                return _DealCard(
                  animation: _riffle,
                  index: i,
                  count: pool.length,
                  child: _ChoiceCard(item: p, onTapDown: (d) => widget.onPlan(p.id, d.globalPosition)),
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
              child: Image.asset(step.scene, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
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
          Text(option.labelBn, textAlign: TextAlign.center, style: zlText(22, weight: FontWeight.w900)),
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
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
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
      _cue(0, 0.02, 'sounds/quiz_complete.wav', volume: 0.9);
      _cue(1, 0.16, 'sounds/quiz_select.wav', volume: 0.38);
      _cue(2, 0.40, 'sounds/quiz_right.wav', volume: 0.72);
      _cue(3, 0.44, 'sounds/quiz_flip.wav', volume: 0.42);
      _cue(4, 0.68, 'sounds/quiz_select.wav', volume: 0.32);
    } else {
      _cue(0, 0.02, 'sounds/accident.wav', volume: 0.88);
      _cue(1, 0.16, 'sounds/quiz_select.wav', volume: 0.34);
      _cue(2, 0.44, 'sounds/quiz_flip.wav', volume: 0.38);
      _cue(3, 0.68, 'sounds/quiz_wrong.wav', volume: 0.72);
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
      animation: Listenable.merge([_show, _burst, _jolt]),
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
              child: CustomPaint(
                painter: _CelebratePainter(time: _burst.value, reveal: drop, ok: _ok),
                child: const SizedBox.expand(),
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
                          child: _ScoreBadge(score: shownScore, ok: _ok, shine: _burst.value),
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
  final double shine;
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
          CustomPaint(painter: _MedalPainter(ok: ok, shine: shine), size: const Size(w, h)),
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
  final double shine;
  const _MedalPainter({required this.ok, required this.shine});

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
        center: Offset(c.dx - r * 0.18 + math.sin(shine * math.pi * 2) * 6, c.dy - r * 0.28),
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
  final double time;
  final double reveal;
  final bool ok;
  const _CelebratePainter({required this.time, required this.reveal, required this.ok});

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(covariant _CelebratePainter old) => old.time != time || old.reveal != reveal || old.ok != ok;
}

class _SceneBoard extends StatelessWidget {
  final DutySlipEngine engine;
  final VoidCallback onNext;
  const _SceneBoard({required this.engine, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('আজকের কাজ', style: zlText(22, weight: FontWeight.w900)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(engine.siteStory, style: zlText(20, weight: FontWeight.w700, height: 1.5, color: ZlColors.cream)),
            ),
          ),
          const SizedBox(height: 16),
          _GentleBtn(label: 'এগোই', onTap: onNext),
        ],
      ),
    );
  }
}

class _GentleBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GentleBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PaperCard(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: zlText(16, weight: FontWeight.w800, color: const Color(0xFF1A140C))),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF6B6256)),
        ],
      ),
    );
  }
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
        item.labelBn,
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
                    child: Image.asset(image, width: 58, height: 58, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.circle_outlined, color: ZlColors.soft)),
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
                child: Image.asset(
                  call.portrait,
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
