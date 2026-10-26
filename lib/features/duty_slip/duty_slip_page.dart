import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home/bangla_read_aloud.dart';
import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'ds_dress_up.dart';
import 'duty_slip_engine.dart';
import 'duty_slip_models.dart';

class DutySlipPage extends StatefulWidget {
  const DutySlipPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const DutySlipPage()),
      );

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
    if (e == null) return;
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
    _tts.stop();
    e.openDress();
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.45, muted: _muted));
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _startLevel() {
    final e = _engine;
    if (e == null || !e.listing) return;
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
    await _tts.speakAwait(_engine?.fill(text) ?? text, rate: 0.42);
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
      return const Scaffold(
        backgroundColor: ZlColors.bg,
        body: Center(child: CircularProgressIndicator(color: ZlColors.amber)),
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

String _bnNum(int n) => '$n';

String _bnCount(int n) {
  const d = '০১২৩৪৫৬৭৮৯';
  return n.toString().split('').map((ch) => d[int.parse(ch)]).join();
}

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
    return _ResultBoard(engine: e, onNext: onNextLevel, onRetry: onRetry, muted: muted);
  }
}

class _CoverBoard extends StatefulWidget {
  final VoidCallback onOpen;
  const _CoverBoard({required this.onOpen});

  @override
  State<_CoverBoard> createState() => _CoverBoardState();
}

class _CoverBoardState extends State<_CoverBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        children: [
          const Spacer(),
          AnimatedBuilder(
            animation: _glow,
            builder: (_, _) {
              final pulse = 0.55 + (0.45 * _glow.value);
              return SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 280,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color.fromRGBO(251, 191, 36, 0.28 * pulse),
                            Color.fromRGBO(253, 230, 138, 0.12 * pulse),
                            const Color(0x00000000),
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'মৃত্যুহীন পথ',
                          textAlign: TextAlign.center,
                          style: zlText(34, weight: FontWeight.w800, height: 1.4, color: const Color(0xFFFFF6D8)).copyWith(
                            shadows: [
                              Shadow(color: Color.fromRGBO(251, 191, 36, 0.85 * pulse), blurRadius: 18),
                              Shadow(color: Color.fromRGBO(255, 247, 214, 0.55 * pulse), blurRadius: 36),
                              const Shadow(color: Color(0x66FFFFFF), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 88,
                          height: 1.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0x00FBBF24),
                                Color.fromRGBO(253, 230, 138, 0.9 * pulse),
                                const Color(0x00FBBF24),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ধাপে ধাপে নিরাপদ',
                          textAlign: TextAlign.center,
                          style: zlText(14, weight: FontWeight.w500, color: const Color(0xFFD6CBB2)).copyWith(
                            shadows: const [Shadow(color: Color(0x66000000), blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _RoundArrow(onTap: widget.onOpen),
          const Spacer(),
        ],
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
  static const _groundH = 140.0;
  static const _sky = 10;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 48))..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pinNext());
  }

  @override
  void didUpdateWidget(covariant _RoadBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine.unlocked != widget.engine.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pinNext());
    }
  }

  void _pinNext() {
    if (!mounted || !_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final focus = dsAllLevelsOpen ? 0 : widget.engine.unlocked;
    final target = (_groundH + focus * _itemH) - (view * 0.28);
    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
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
        const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _NightSkyPainter()))),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'মৃত্যুহীন পথ',
                textAlign: TextAlign.center,
                style: zlText(26, weight: FontWeight.w800, height: 1.2, color: const Color(0xFF8F8160)).copyWith(
                  shadows: const [
                    Shadow(offset: Offset(0, -1), color: Color(0x99000000), blurRadius: 0),
                    Shadow(offset: Offset(0, 1), color: Color(0x220E1824), blurRadius: 0),
                  ],
                ),
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

class _NightSkyPainter extends CustomPainter {
  const _NightSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050A14), Color(0xFF0B1830), Color(0xFF143044), Color(0xFF1A3340)],
          stops: [0.0, 0.32, 0.62, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SkyMotionPainter extends CustomPainter {
  final double time;
  final double scroll;
  const _SkyMotionPainter({required this.time, required this.scroll});

  static const _clouds = <_CloudSpec>[
    _CloudSpec(y: 0.08, x: 0.04, speed: 0.10, scale: 1.15, parallax: 0.04, phase: 0.2),
    _CloudSpec(y: 0.14, x: 0.52, speed: 0.14, scale: 0.95, parallax: 0.06, phase: 1.1),
    _CloudSpec(y: 0.22, x: 0.22, speed: 0.18, scale: 0.82, parallax: 0.09, phase: 2.4),
    _CloudSpec(y: 0.30, x: 0.72, speed: 0.12, scale: 1.08, parallax: 0.11, phase: 0.7),
    _CloudSpec(y: 0.38, x: 0.38, speed: 0.16, scale: 0.7, parallax: 0.14, phase: 1.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rise = (scroll / 1100).clamp(0.0, 1.0);

    final moon = Offset(w * 0.82, h * 0.13 + scroll * 0.05);
    canvas.drawCircle(moon, 26, Paint()..color = const Color(0x18FFF6D8));
    canvas.drawCircle(moon, 12, Paint()..color = const Color(0xCCFFF4C2));

    final star = Paint()..color = const Color(0x88FFF8E1);
    final rng = math.Random(11);
    for (var i = 0; i < 18; i++) {
      final p = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.48 + scroll * 0.035);
      if (p.dy > h * 0.52) continue;
      canvas.drawCircle(p, rng.nextDouble() * 1.15 + 0.35, star);
    }

    for (final c in _clouds) {
      final span = w + 200;
      var x = c.x * w + time * c.speed * span;
      x = x % span;
      if (x < 0) x += span;
      x -= 90;
      var y = h * c.y + scroll * c.parallax + math.sin((time * math.pi * 2) + c.phase) * 4;
      if (y > h * 0.48) continue;
      _cloudPuff(canvas, Offset(x, y), c.scale);
    }

    final horizon = h * 0.56 + scroll * 0.10;
    _cityBand(canvas, w, horizon, rise, time, far: true);
    _cityBand(canvas, w, horizon + 10, rise, time, far: false);
  }

  @override
  bool shouldRepaint(covariant _SkyMotionPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.scroll != scroll;
}

class _CloudSpec {
  final double y;
  final double x;
  final double speed;
  final double scale;
  final double parallax;
  final double phase;
  const _CloudSpec({
    required this.y,
    required this.x,
    required this.speed,
    required this.scale,
    required this.parallax,
    required this.phase,
  });
}

void _cloudPuff(Canvas canvas, Offset o, double s) {
  final body = Paint()..color = const Color(0x2CEEF2F8);
  final lit = Paint()..color = const Color(0x18FFFFFF);
  canvas.drawOval(Rect.fromCenter(center: o, width: 118 * s, height: 30 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-36 * s, -5 * s), width: 64 * s, height: 26 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(38 * s, -7 * s), width: 58 * s, height: 24 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(6 * s, -14 * s), width: 48 * s, height: 22 * s), body);
  canvas.drawOval(Rect.fromCenter(center: o + Offset(-8 * s, -11 * s), width: 40 * s, height: 16 * s), lit);
}

void _cityBand(Canvas canvas, double w, double baseY, double rise, double time, {required bool far}) {
  final rng = math.Random(far ? 3 : 9);
  var x = -10.0;
  final fill = Paint()..color = far ? const Color(0xFF0A1524) : const Color(0xFF070E18);
  final heightScale = far ? 0.62 : 0.92;
  while (x < w + 24) {
    final bw = 16.0 + rng.nextDouble() * (far ? 26 : 34);
    final bh = (18 + rng.nextDouble() * 64) * heightScale;
    canvas.drawRect(Rect.fromLTWH(x, baseY - bh, bw, bh + 36), fill);
    final cols = (bw / 6).floor().clamp(1, 5);
    final rows = (bh / 8).floor().clamp(1, 9);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (rng.nextDouble() > 0.10 + rise * 0.72) continue;
        final flicker = 0.72 + 0.28 * math.sin(time * math.pi * 2 * 2.4 + r * 0.8 + c * 1.3 + (far ? 0 : 2));
        final a = ((0.12 + rise * 0.78) * flicker).clamp(0.0, 0.92);
        canvas.drawRect(
          Rect.fromLTWH(x + 3 + c * 5.6, baseY - bh + 4 + r * 7.6, 2.3, 3.1),
          Paint()..color = Color.fromRGBO(255, 214, 120, a),
        );
      }
    }
    x += bw + 2 + rng.nextDouble() * 7;
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final soil = Path()
      ..moveTo(0, h * 0.42)
      ..quadraticBezierTo(w * 0.25, h * 0.34, w * 0.5, h * 0.4)
      ..quadraticBezierTo(w * 0.75, h * 0.48, w, h * 0.38)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      soil,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF3D5A2A), Color(0xFF2C3F1C), Color(0xFF24180E)],
        ).createShader(Offset.zero & size),
    );
    _tree(canvas, Offset(w * 0.12, h * 0.18), 0.72);
    _tree(canvas, Offset(w * 0.9, h * 0.14), 0.78);
    final cx = w / 2;
    const gap = 34.0;
    _bambooPole(canvas, cx - gap, 0, h * 0.58, 13);
    _bambooPole(canvas, cx + gap, 0, h * 0.58, 13);
    _bambooRung(canvas, cx, h * 0.22, gap);
    final mound = Paint()..color = const Color(0xFF4A3420);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - gap, h * 0.6), width: 28, height: 14), mound);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + gap, h * 0.6), width: 28, height: 14), mound);
    final rng = math.Random(21);
    final blade = Paint()
      ..color = const Color(0x996B8F3C)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * w;
      final y = h * 0.52 + rng.nextDouble() * h * 0.32;
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + (rng.nextBool() ? 4 : -4), y - 10, x + (rng.nextBool() ? 2 : -2), y - 16);
      canvas.drawPath(path, blade);
    }
    _flower(canvas, Offset(w * 0.24, h * 0.7), const Color(0xFFF472B6), 5);
    _flower(canvas, Offset(w * 0.72, h * 0.66), const Color(0xFFFACC15), 5);
    _flower(canvas, Offset(w * 0.86, h * 0.78), const Color(0xFFF9A8D4), 4.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    const gap = 34.0;
    if (!sky && index < 2) {
      _leaves(canvas, Offset(w * 0.14, h * 0.5), index, left: true, thin: true);
      _leaves(canvas, Offset(w * 0.88, h * 0.48), index + 3, left: false, thin: true);
    }
    _bambooPole(canvas, cx - gap, 0, h, 13);
    _bambooPole(canvas, cx + gap, 0, h, 13);
    _bambooRung(canvas, cx, h / 2, gap);
  }

  @override
  bool shouldRepaint(covariant _BambooRungPainter oldDelegate) => oldDelegate.index != index || oldDelegate.sky != sky;
}

void _bambooPole(Canvas canvas, double x, double top, double bot, double width) {
  final rect = Rect.fromLTRB(x - width / 2, top, x + width / 2, bot);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(8)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0xFF5C4316), Color(0xFFC6B15A), Color(0xFFE8D98A), Color(0xFF8A6A28), Color(0xFF4A3510)],
        stops: const [0.0, 0.28, 0.48, 0.78, 1.0],
      ).createShader(rect),
  );
  canvas.drawRRect(
    RRect.fromLTRBR(x - width / 2 + 2.2, top + 2, x - 1.4, bot - 2, const Radius.circular(6)),
    Paint()..color = const Color(0x55FFF6D8),
  );
  final nodeY = (top + bot) / 2;
  canvas.drawRRect(
    RRect.fromLTRBR(x - width / 2 - 1.6, nodeY - 3.2, x + width / 2 + 1.6, nodeY + 3.2, const Radius.circular(4)),
    Paint()..color = const Color(0xFF6B4E16),
  );
  canvas.drawLine(
    Offset(x - width / 2 - 1, nodeY),
    Offset(x + width / 2 + 1, nodeY),
    Paint()
      ..color = const Color(0xFF3F2A0C)
      ..strokeWidth = 1.1,
  );
}

void _bambooRung(Canvas canvas, double cx, double y, double gap) {
  final rect = Rect.fromLTRB(cx - gap - 7, y - 6, cx + gap + 7, y + 6);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(7)),
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6B4E16), Color(0xFFD4C078), Color(0xFF8A6A28)],
      ).createShader(rect),
  );
  canvas.drawCircle(Offset(cx, y), 3.2, Paint()..color = const Color(0xFF5C4316));
  final wrap = Paint()
    ..color = const Color(0xFF3F2A0C)
    ..strokeWidth = 1.3
    ..style = PaintingStyle.stroke;
  canvas.drawOval(Rect.fromCenter(center: Offset(cx - gap, y), width: 16, height: 14), wrap);
  canvas.drawOval(Rect.fromCenter(center: Offset(cx + gap, y), width: 16, height: 14), wrap);
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

class _LevelOrb extends StatelessWidget {
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

  List<Color> get _plate {
    if (locked) return const [Color(0xFFC5CAD0), Color(0xFF8A919A), Color(0xFF4E555E)];
    if (rank == DsLevelRank.darun) return const [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)];
    if (rank == DsLevelRank.motamuti) return const [Color(0xFFD8CDB0), Color(0xFF9A8A68), Color(0xFF5C5040)];
    if (next) return const [Color(0xFFF0DFA8), Color(0xFFC4A03A), Color(0xFF7A5C14)];
    if (field) return const [Color(0xFFC8CCD2), Color(0xFF6E7680), Color(0xFF3A4048)];
    return const [Color(0xFFE2C090), Color(0xFFA07840), Color(0xFF5E4020)];
  }

  @override
  Widget build(BuildContext context) {
    final metal = _plate;
    final stamp = (locked || bestSec == null)
        ? ''
        : '${(bestSec! ~/ 60).toString().padLeft(2, '0')}:${(bestSec! % 60).toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: metal,
              stops: const [0.0, 0.46, 1.0],
            ),
            border: Border.all(color: metal.last, width: 1.15),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), offset: Offset(0, 1.5), blurRadius: 1.2),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 1.2,
                left: 3,
                right: 3,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
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
              const Positioned(left: 5, top: 0, bottom: 0, child: Center(child: _MetalRivet())),
              const Positioned(right: 5, top: 0, bottom: 0, child: Center(child: _MetalRivet())),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: stamp.isEmpty ? 0 : 7),
                  child: Text(
                    _bnNum(number),
                    style: zlText(16, weight: FontWeight.w900, color: const Color(0xFF1C1408)).copyWith(
                      shadows: const [
                        Shadow(offset: Offset(0, 1), color: Color(0x55FFFFFF), blurRadius: 0),
                        Shadow(offset: Offset(0, -0.6), color: Color(0x66000000), blurRadius: 0),
                      ],
                    ),
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
  final bool muted;
  const _ResultBoard({required this.engine, required this.onNext, required this.onRetry, required this.muted});

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
