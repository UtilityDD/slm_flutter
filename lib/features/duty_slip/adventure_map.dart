import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_sheet.dart';
import '../quizzes/identify_quiz_screen.dart';
import '../quizzes/quiz_play_screen.dart';
import '../training/training_screen.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'adventure_scenery.dart';
import 'duty_slip_engine.dart';
import 'duty_slip_voice.dart';

/// Winding valley journey. Stop positions come from the index, so level 3 and
/// level 100 use the same widgets. This screen does not award points.
class AdventureMap extends StatefulWidget {
  final DutySlipEngine engine;
  final void Function(int index) onOpen;
  final ValueNotifier<double> scrollOut;
  final bool muted;
  final VoidCallback onInfo;

  const AdventureMap({
    super.key,
    required this.engine,
    required this.onOpen,
    required this.scrollOut,
    required this.muted,
    required this.onInfo,
  });

  @override
  State<AdventureMap> createState() => _AdventureMapState();
}

enum _Station { tips, hourly, identify, gift, life, lesson }

_Station? _stationAt(int index) => switch (index % 8) {
      1 => _Station.tips,
      2 => _Station.hourly,
      3 => _Station.identify,
      5 => _Station.gift,
      6 => _Station.life,
      7 => _Station.lesson,
      _ => null,
    };

/// Gentle left-right weave. Adjacent stops stay close so each step climbs
/// much farther than it drifts, and the path never leaves the centre corridor.
double _lane(int index, double width) {
  const stops = [0.47, 0.54, 0.45, 0.55, 0.46, 0.53, 0.48, 0.52];
  return width * stops[index % stops.length];
}

class _AdventureMapState extends State<AdventureMap> with SingleTickerProviderStateMixin {
  static const _rowH = 118.0;
  static const _tail = 6;

  final _scroll = ScrollController();
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_publish);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) _glow.repeat(reverse: true);
      _pin(initial: true);
    });
  }

  @override
  void didUpdateWidget(covariant AdventureMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine.unlocked != widget.engine.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pin());
    }
  }

  void _publish() {
    if (!_scroll.hasClients) return;
    if (widget.scrollOut.value != _scroll.offset) widget.scrollOut.value = _scroll.offset;
  }

  void _pin({bool initial = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final view = _scroll.position.viewportDimension;
    final target = (widget.engine.unlocked * _rowH) - (view * 0.22);
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent);
    if (initial) {
      _scroll.jumpTo(0);
      _scroll.animateTo(clamped, duration: const Duration(milliseconds: 850), curve: Curves.easeOutCubic);
    } else {
      _scroll.animateTo(clamped, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_publish);
    _scroll.dispose();
    _glow.dispose();
    super.dispose();
  }

  int _lit(_Station kind, int focus, int live) {
    for (var i = math.max(0, focus - 1); i <= focus + 3 && i < live; i++) {
      if (_stationAt(i) == kind) return i;
    }
    return -1;
  }

  void _openLevel(int index) {
    final spec = dsLevels[index];
    if (gameNeedsVerifyNow(context, spec.number)) {
      showVerifySheet(context);
      return;
    }
    final locked = !dsPlayAllLevels && index > widget.engine.unlocked;
    if (locked) return;
    HapticFeedback.selectionClick();
    widget.onOpen(index);
  }

  void _openStation(_Station station, int index) {
    HapticFeedback.lightImpact();
    switch (station) {
      case _Station.hourly:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuizPlayScreen()));
      case _Station.identify:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IdentifyQuizScreen()));
      case _Station.lesson:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrainingScreen()));
      case _Station.tips || _Station.life:
        unawaited(_showSheet(
          title: station == _Station.tips ? 'নিরাপত্তা টিপস' : 'লাইফ স্কিল কুইজ',
          body: dsBriefFor(dsLevels[index.clamp(0, dsLevels.length - 1).toInt()]).body,
          speak: true,
        ));
      case _Station.gift:
        unawaited(_showSheet(
          title: 'সারপ্রাইজ গিফট',
          body: 'পরের ধাপগুলো খুললে এই বক্সে বিশেষ চ্যালেঞ্জ পাবেন।',
          speak: false,
        ));
    }
  }

  Future<void> _showSheet({required String title, required String body, required bool speak}) async {
    if (speak && !widget.muted) unawaited(DsVoice.play(body, muted: false));
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: SlmColors.navy900,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + MediaQuery.viewPaddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: zlText(16, weight: FontWeight.w800, color: SlmColors.gold200)),
            const SizedBox(height: 8),
            Text(enDigits(body), style: zlText(15, weight: FontWeight.w600, color: SlmColors.ivory, height: 1.45)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final live = dsLevels.length;
    final focus = e.unlocked.clamp(0, math.max(0, live - 1)).toInt();
    final quiet = MediaQuery.disableAnimationsOf(context);
    final lit = <_Station, int>{
      for (final s in _Station.values) s: _lit(s, focus, live),
    };

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final glow = quiet ? 0.6 : _glow.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                _TopHeader(
                  engine: e,
                  focus: focus,
                  live: live,
                  onBack: () => Navigator.of(context).maybePop(),
                  onInfo: widget.onInfo,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    scrollDirection: Axis.vertical,
                    reverse: true,
                    physics: const ClampingScrollPhysics(),
                    clipBehavior: Clip.hardEdge,
                    itemCount: live + _tail,
                    itemExtent: _rowH,
                    padding: const EdgeInsets.only(top: 24, bottom: 72),
                    itemBuilder: (context, i) {
                      final soon = i >= live;
                      final fog = i > focus + 3;
                      final station = soon ? null : _stationAt(i);
                      final isLit = station != null && lit[station] == i && !fog;
                      return _MapBand(
                        index: i,
                        number: soon ? i + 1 : dsLevels[i].number,
                        soon: soon,
                        fog: fog,
                        crest: i == focus + 3 || i == live - 1,
                        cleared: !soon && (i < focus || (e.bestRank[i] != null && e.bestRank[i] != DsLevelRank.again)),
                        current: !soon && i == focus,
                        locked: soon || i > focus,
                        glow: glow,
                        station: station,
                        stationLit: isLit,
                        stationDone: !soon && i < focus,
                        onLevel: soon
                            ? () {
                                HapticFeedback.selectionClick();
                                unawaited(_showSheet(
                                  title: 'শীঘ্রই আসছে',
                                  body: 'এই ধাপটি এখনো খোলেনি।',
                                  speak: false,
                                ));
                              }
                            : () => _openLevel(i),
                        onStation: station == null ? null : () => _openStation(station, i),
                      );
                    },
                  ),
                ),
              ],
            ),
            const Positioned(
              right: 0,
              bottom: 54,
              child: SizedBox(width: 74, height: 100, child: FittedBox(alignment: Alignment.bottomRight, child: CornerLineman())),
            ),
            const Positioned(left: 10, right: 10, bottom: 6, child: _LegendBar()),
          ],
        );
      },
    );
  }
}

/// Outer brushed-gold bezel around a dark navy or emerald housing.
class _GoldShell extends StatelessWidget {
  final double radius;
  final double rim;
  final Gradient fill;
  final EdgeInsets padding;
  final Widget child;

  const _GoldShell({
    required this.radius,
    this.rim = 1.25,
    this.fill = SlmGradients.navyCard,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final inner = math.max(0.0, radius - rim);
    return Container(
      padding: EdgeInsets.all(rim),
      decoration: BoxDecoration(
        gradient: SlmGradients.gold,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: fill,
          borderRadius: BorderRadius.circular(inner),
        ),
        child: child,
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final DutySlipEngine engine;
  final int focus;
  final int live;
  final VoidCallback onBack;
  final VoidCallback onInfo;

  const _TopHeader({
    required this.engine,
    required this.focus,
    required this.live,
    required this.onBack,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    var cleared = 0;
    for (final r in e.bestRank) {
      if (r != null && r != DsLevelRank.again) cleared++;
    }
    final pct = live == 0 ? 0 : ((math.max(cleared, focus + 1) * 100) / live).round().clamp(0, 100);
    final calm = e.totalCumulativeDanger == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Column(
        children: [
          Row(
            children: [
              _CircleIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AnimatedSafetyShield(size: 46, animate: false),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [SlmColors.gold100, SlmColors.gold300, SlmColors.gold500],
                          ).createShader(rect),
                          child: Text(
                            'মৃত্যুহীন পথ',
                            style: zlText(21, weight: FontWeight.w900, color: Colors.white, height: 1.08).copyWith(
                              letterSpacing: 0.3,
                              shadows: const [Shadow(color: Color(0xCC000000), offset: Offset(0, 2), blurRadius: 4)],
                            ),
                          ),
                        ),
                        Text(
                          'নিরাপত্তার অভিযাত্রা',
                          style: zlText(11, weight: FontWeight.w700, color: SlmColors.ivory, height: 1.15).copyWith(
                            letterSpacing: 0.2,
                            shadows: const [Shadow(color: Color(0xAA000000), offset: Offset(0, 1), blurRadius: 2)],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _CircleIcon(icon: Icons.info_outline_rounded, onTap: onInfo),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _GoldShell(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const Icon(Icons.stars_rounded, size: 15, color: SlmColors.gold300),
                      const SizedBox(width: 3),
                      Text('${e.totalCumulativeScore} XP', style: zlText(12, weight: FontWeight.w900, color: SlmColors.ivory)),
                      _divider(),
                      Icon(Icons.shield_rounded, size: 14, color: calm ? SlmColors.emerald400 : SlmColors.danger),
                      const SizedBox(width: 3),
                      Text('${e.totalCumulativeDanger}', style: zlText(12, weight: FontWeight.w900, color: SlmColors.ivory)),
                      _divider(),
                      const Icon(Icons.access_time_filled_rounded, size: 13.5, color: SlmColors.gold300),
                      const SizedBox(width: 3),
                      Text(e.formatClock(e.totalCumulativeSeconds), style: zlText(11.5, weight: FontWeight.w800, color: SlmColors.ivory)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _LevelCrest(level: focus + 1, pct: pct),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 1,
        height: 13,
        color: SlmColors.gold400.withValues(alpha: 0.32),
      );
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.06 * press, child: child),
      child: _GoldShell(
        radius: 18,
        rim: 1.15,
        child: SizedBox(
          width: 33,
          height: 33,
          child: Icon(icon, size: 17, color: SlmColors.gold100),
        ),
      ),
    );
  }
}

class _LevelCrest extends StatelessWidget {
  final int level;
  final int pct;

  const _LevelCrest({required this.level, required this.pct});

  @override
  Widget build(BuildContext context) {
    return _GoldShell(
      radius: 18,
      fill: SlmGradients.navyHero,
      padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: SlmGradients.emerald,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SlmColors.gold200, width: 1),
            ),
            child: Column(
              children: [
                Text('লেভেল', style: zlText(7.5, weight: FontWeight.w700, color: SlmColors.gold100, height: 1.05)),
                Text('$level', style: zlText(12, weight: FontWeight.w900, color: SlmColors.ivory, height: 1.05)),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$pct%', style: zlText(11, weight: FontWeight.w900, color: SlmColors.gold100, height: 1.0)),
              const SizedBox(height: 3),
              Container(
                width: 48,
                height: 5.5,
                padding: const EdgeInsets.all(0.7),
                decoration: BoxDecoration(
                  color: SlmColors.navy950,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: SlmColors.gold500.withValues(alpha: 0.45), width: 0.7),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: SlmGradients.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapBand extends StatelessWidget {
  final int index;
  final int number;
  final bool soon;
  final bool fog;
  final bool crest;
  final bool cleared;
  final bool current;
  final bool locked;
  final double glow;
  final _Station? station;
  final bool stationLit;
  final bool stationDone;
  final VoidCallback? onLevel;
  final VoidCallback? onStation;

  const _MapBand({
    required this.index,
    required this.number,
    required this.soon,
    required this.fog,
    required this.crest,
    required this.cleared,
    required this.current,
    required this.locked,
    required this.glow,
    required this.station,
    required this.stationLit,
    required this.stationDone,
    required this.onLevel,
    required this.onStation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final x = _lane(index, w);
        final prev = _lane(index == 0 ? 0 : index - 1, w);
        final next = _lane(index + 1, w);
        final slot = index % 8;
        final markLeft = index.isEven;
        final lift = _hillLift(index);
        final roadBottom = Offset((prev + x) / 2, h);
        final roadHere = Offset(x, h * 0.5 - lift);
        final roadTop = Offset((x + next) / 2, 0);
        final onRoad = Offset(
          0.25 * roadBottom.dx + 0.5 * roadHere.dx + 0.25 * roadTop.dx,
          0.25 * roadBottom.dy + 0.5 * roadHere.dy + 0.25 * roadTop.dy,
        );

        return Opacity(
          opacity: fog ? 0.35 : 1,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _DioramaGroundPainter(
                  index: index,
                  river: slot == 2,
                ),
              ),
              CustomPaint(
                size: Size(w, h),
                painter: _GoldenRoadPainter(
                  bottom: roadBottom,
                  here: roadHere,
                  top: roadTop,
                  fog: fog,
                  slot: slot,
                ),
              ),
              if (!soon && _landmarkFor(slot) != null)
                Positioned(
                  left: markLeft ? 0 : null,
                  right: markLeft ? null : 0,
                  bottom: 0,
                  width: w * 0.26,
                  child: Align(
                    alignment: markLeft ? Alignment.bottomLeft : Alignment.bottomRight,
                    child: _Seated(shadow: 36, child: _landmarkFor(slot)!),
                  ),
                ),
              if (crest && !soon)
                Positioned(
                  left: markLeft ? 4 : null,
                  right: markLeft ? null : 4,
                  top: 0,
                  child: const _FitMark(height: 36, child: ZeroDeathCrest()),
                ),
              Positioned(
                left: onRoad.dx - 26,
                top: onRoad.dy - 26,
                child: _LevelCoin(
                  number: number,
                  soon: soon,
                  cleared: cleared,
                  current: current,
                  locked: locked,
                  glow: glow,
                  onTap: onLevel,
                ),
              ),
              if (station != null)
                Positioned(
                  left: markLeft ? null : 2,
                  right: markLeft ? 2 : null,
                  top: 36,
                  child: _StationPlaque(
                    station: station!,
                    lit: stationLit,
                    done: stationDone,
                    glow: glow,
                    onTap: onStation,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// How far the road crests above the band midline. Endpoints stay on the
/// band edges so neighbouring bands still meet.
double _hillLift(int index) => 5 * math.sin(index * 0.85 + 0.3);

/// One slim landmark for this band, kept in the side gutter.
Widget? _landmarkFor(int slot) {
  return switch (slot) {
    0 => const _FitMark(height: 50, child: TrainingShed()),
    1 || 4 => const _FitMark(height: 68, child: _PoleMark()),
    2 => const _FitMark(height: 40, child: BridgeArch3D()),
    3 => const _FitMark(height: 54, child: DtrStation()),
    5 || 7 => const _FitMark(height: 38, child: TreeCluster3D(size: 52)),
    6 => const _FitMark(height: 50, child: SubstationYard()),
    _ => null,
  };
}

class _GoldenRoadPainter extends CustomPainter {
  final Offset bottom;
  final Offset here;
  final Offset top;
  final bool fog;
  final int slot;

  const _GoldenRoadPainter({
    required this.bottom,
    required this.here,
    required this.top,
    required this.fog,
    required this.slot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..quadraticBezierTo(here.dx, here.dy, top.dx, top.dy);

    // Soil cut the ribbon sits in, then the raised gold surface.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 38
        ..strokeCap = StrokeCap.round
        ..color = fog ? const Color(0x3320140C) : const Color(0xFF24160C),
    );
    final bank = path.shift(const Offset(2.5, 5.5));
    canvas.drawPath(
      bank,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round
        ..color = fog ? const Color(0x33000000) : const Color(0x7707120B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path.shift(const Offset(1.2, 3.2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3E270B),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 23
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF76521B),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round
        ..color = fog ? const Color(0xFFB59B67) : SlmColors.gold400,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = fog ? const Color(0xFFCBB686) : SlmColors.gold200,
    );
    canvas.drawPath(
      path.shift(const Offset(-1.5, -1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xBBFAF1DA),
    );

    // Overhead 3-phase 11kV catenary distribution conductors along the valley
    if (!fog && (slot == 1 || slot == 2 || slot == 3 || slot == 4)) {
      final wirePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = const Color(0x88E2E8F0);
      for (final d in [-6.0, 0.0, 6.0]) {
        final wPath = Path()
          ..moveTo(bottom.dx + 12 + d, bottom.dy)
          ..quadraticBezierTo(here.dx + 12 + d, here.dy + 4, top.dx + 12 + d, top.dy);
        canvas.drawPath(wPath, wirePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenRoadPainter oldDelegate) =>
      oldDelegate.here != here || oldDelegate.fog != fog || oldDelegate.slot != slot;
}

/// Rolling miniature ground for one map band. Mound centres are in world
/// space so a hill continues into the bands above and below.
class _DioramaGroundPainter extends CustomPainter {
  final int index;
  final bool river;

  const _DioramaGroundPainter({required this.index, required this.river});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);

    canvas.drawRect(rect, Paint()..color = const Color(0xFF5F8C44));

    // Soft brightness along the climb. Tall and faint, so it reads as a slope
    // in a corridor rather than a round hill sitting across the screen.
    for (var m = index - 1; m <= index + 1; m++) {
      final localCy = (index - m + 0.5) * h;
      final crown = Rect.fromCenter(center: Offset(w * 0.5, localCy), width: w * 0.62, height: h * 0.85);
      canvas.drawOval(
        crown,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -0.15),
            radius: 1.05,
            colors: [Color(0x5599C86C), Color(0x2299C86C), Color(0x0099C86C)],
            stops: [0.0, 0.42, 1.0],
          ).createShader(crown),
      );
    }

    // Valley walls. Darker at the screen edges, open down the middle.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xE02A461E), Color(0x002A461E), Color(0x002A461E), Color(0xD0243C1A)],
          stops: [0.0, 0.30, 0.70, 1.0],
        ).createShader(rect),
    );

    final rng = math.Random(index * 17 + 3);
    final grass = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xAAB6D86A);
    for (var i = 0; i < 8; i++) {
      final leftSide = i.isEven;
      final gx = leftSide ? 6 + rng.nextDouble() * w * 0.16 : w - 6 - rng.nextDouble() * w * 0.16;
      final gy = h * (0.2 + rng.nextDouble() * 0.6);
      canvas.drawLine(Offset(gx, gy), Offset(gx + (leftSide ? 1.1 : -1.1), gy - 4), grass);
    }
    if (index.isEven) {
      final rock = Rect.fromCenter(
        center: Offset(w * 0.08, h * 0.62),
        width: 9,
        height: 5,
      );
      canvas.drawOval(
        rock,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            colors: [Color(0xFFE4DDD2), Color(0xFF6E675C)],
          ).createShader(rock),
      );
    }

    if (river) _paintRiver(canvas, size);
    canvas.restore();
  }

  void _paintRiver(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    const steps = 8;
    for (var s = 0; s <= steps; s++) {
      final t = s / steps;
      final x = w * (0.08 + 0.015 * math.sin((index + t) * 1.6));
      final y = t * h;
      if (s == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1A140E),
    );
    canvas.drawPath(
      path.shift(const Offset(2, 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6B4A2A),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2E9CC0),
    );
    canvas.drawPath(
      path.shift(const Offset(-0.8, -0.8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCF2FBFF),
    );
  }

  @override
  bool shouldRepaint(covariant _DioramaGroundPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.river != river;
}

class _ContactShadow extends StatelessWidget {
  final double width;

  const _ContactShadow({required this.width});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: width * 0.26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(width, width * 0.26)),
          color: const Color(0x99060C08),
          boxShadow: const [BoxShadow(color: Color(0x66060C08), blurRadius: 5, offset: Offset(2, 1))],
        ),
      ),
    );
  }
}

class _FitMark extends StatelessWidget {
  final double height;
  final Widget child;

  const _FitMark({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: FittedBox(fit: BoxFit.contain, child: child));
  }
}

class _PoleMark extends StatelessWidget {
  const _PoleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 70,
      height: 96,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Pole3D(),
          Positioned(
            right: 0,
            bottom: 6,
            child: Image(
              image: AssetImage('assets/zero_loss/scene/spr_man_climb.webp'),
              width: 26,
              height: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _Seated extends StatelessWidget {
  final double shadow;
  final Widget child;

  const _Seated({required this.shadow, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(bottom: -1, child: _ContactShadow(width: shadow)),
        child,
      ],
    );
  }
}

class _LevelCoin extends StatelessWidget {
  final int number;
  final bool soon;
  final bool cleared;
  final bool current;
  final bool locked;
  final double glow;
  final VoidCallback? onTap;

  const _LevelCoin({
    required this.number,
    required this.soon,
    required this.cleared,
    required this.current,
    required this.locked,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = soon || (locked && !cleared && !current);
    final asset = muted
        ? 'assets/duty_slip/world3d/coin_locked_3d.webp'
        : cleared
            ? 'assets/duty_slip/world3d/coin_cleared_3d.webp'
            : 'assets/duty_slip/world3d/coin_current_3d.webp';

    final alive = onTap != null && !soon && !locked;
    final disc = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const Positioned(
          bottom: -2,
          child: _ContactShadow(width: 34),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: alive
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (current ? SlmColors.gold300 : SlmColors.emerald400)
                          .withValues(alpha: current ? 0.35 + 0.4 * glow : 0.22 + 0.15 * glow),
                      blurRadius: current ? 16 + 6 * glow : 10,
                      spreadRadius: current ? 2 : 0.5,
                    ),
                  ],
                )
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                asset,
                width: 56,
                height: 56,
                cacheWidth: 150,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
              Text(
                '$number',
                style: zlText(18, weight: FontWeight.w900, color: SlmColors.ivory).copyWith(
                  shadows: const [Shadow(color: Color(0xDD000000), offset: Offset(0, 1.5), blurRadius: 2.5)],
                ),
              ),
            ],
          ),
        ),
        if (cleared || (locked && !current))
          Positioned(
            right: cleared ? -1 : null,
            bottom: -3,
            child: _StatusPip(cleared: cleared),
          ),
      ],
    );

    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) => Transform.scale(
        scale: 1 - 0.07 * press,
        child: current ? SlmShimmer(intensity: 0.28, child: child!) : child,
      ),
      child: disc,
    );
  }
}

class _StatusPip extends StatelessWidget {
  final bool cleared;

  const _StatusPip({required this.cleared});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      padding: const EdgeInsets.all(1.2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SlmGradients.gold,
        boxShadow: [BoxShadow(color: Color(0x88000000), blurRadius: 3, offset: Offset(0, 1.5))],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: cleared ? SlmGradients.emerald : SlmGradients.navyCard,
        ),
        child: Icon(
          cleared ? Icons.check_rounded : Icons.lock_rounded,
          size: 10.5,
          color: SlmColors.ivory,
        ),
      ),
    );
  }
}

class _StationPlaque extends StatelessWidget {
  final _Station station;
  final bool lit;
  final bool done;
  final double glow;
  final VoidCallback? onTap;

  const _StationPlaque({
    required this.station,
    required this.lit,
    required this.done,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (station) {
      _Station.tips => Icons.verified_user_rounded,
      _Station.hourly => Icons.bolt_rounded,
      _Station.identify => Icons.manage_search_rounded,
      _Station.gift => Icons.redeem_rounded,
      _Station.life => Icons.diversity_3_rounded,
      _Station.lesson => Icons.auto_stories_rounded,
    };
    final chest = station == _Station.gift;
    final medallionAsset = switch (station) {
      _Station.tips || _Station.life => 'assets/duty_slip/world3d/medallion_emerald_3d.webp',
      _Station.gift => 'assets/duty_slip/world3d/medallion_bronze_3d.webp',
      _ => 'assets/duty_slip/world3d/medallion_navy_3d.webp',
    };
    final pulse = lit ? 0.45 + 0.55 * glow : 0.28 + 0.12 * glow;
    final emblem = chest
        ? Image.asset(
            'assets/duty_slip/world3d/chest_treasure_3d.webp',
            width: 44,
            height: 40,
            cacheWidth: 140,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        : SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  medallionAsset,
                  width: 40,
                  height: 40,
                  cacheWidth: 120,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                Icon(icon, color: SlmColors.gold100, size: 16),
              ],
            ),
          );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: Offset(0, lit ? -3 * glow : 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (chest ? SlmColors.gold300 : SlmColors.emerald400).withValues(alpha: 0.25 + 0.45 * pulse),
                  blurRadius: 12 + 10 * pulse,
                  spreadRadius: lit ? 2 : 0.4,
                ),
              ],
            ),
            child: emblem,
          ),
        ),
        if (done) const _StatusPip(cleared: true),
      ],
    );

    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: body,
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: _GoldShell(
          radius: 22,
          rim: 1.15,
          fill: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xD90A1428), Color(0xEE050A16)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(
                fill: SlmGradients.emerald,
                icon: Icons.check_rounded,
                label: 'সম্পন্ন',
              ),
              _LegendItem(
                fill: SlmGradients.gold,
                icon: Icons.circle,
                label: 'বর্তমান',
                darkIcon: true,
              ),
              _LegendItem(
                fill: SlmGradients.navyCard,
                icon: Icons.lock_rounded,
                label: 'লকড',
              ),
              _LegendItem(
                fill: SlmGradients.bronze,
                icon: Icons.redeem_rounded,
                label: 'বিশেষ চ্যালেঞ্জ',
                darkIcon: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Gradient fill;
  final IconData icon;
  final String label;
  final bool darkIcon;

  const _LegendItem({
    required this.fill,
    required this.icon,
    required this.label,
    this.darkIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          padding: const EdgeInsets.all(1.1),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SlmGradients.gold,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: fill),
            child: Icon(icon, size: 10.5, color: darkIcon ? SlmColors.navy950 : SlmColors.ivory),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: zlText(9.5, weight: FontWeight.w800, color: SlmColors.ivory, height: 1.1)),
      ],
    );
  }
}
