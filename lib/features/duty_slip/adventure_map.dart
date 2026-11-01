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

/// Monumental golden ladder. The bamboo climb in commit 4672672
/// (`_RoadBoard`, `_BambooRungPainter`) is the layout this screen recovers:
/// vertical rails, one rung per level, the checkpoint on the rung.
/// Stop numbers still come from [dsLevels]. This screen does not award points.
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

class _AdventureMapState extends State<AdventureMap> with SingleTickerProviderStateMixin {
  static const _rowH = 108.0;
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
    final activityAt = <int>{};
    for (var n = focus; n < focus + 5 && n < live; n++) {
      if (_stationAt(n) != null) activityAt.add(n);
      if (activityAt.length == 2) break;
    }
    final quietBands = [for (var n = focus; n < focus + 5 && n < live; n++) n].where((n) => !activityAt.contains(n)).toList();
    final poleAt = quietBands.isEmpty ? -1 : quietBands.first;
    final dtrAt = quietBands.length < 2 ? -1 : quietBands[1];

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
                      final showcase = !soon && i >= focus && i < focus + 5;
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
                        showcase: showcase,
                        featuredActivity: activityAt.contains(i),
                        pole: i == poleAt,
                        dtr: i == dtrAt,
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
  final bool showcase;
  final bool featuredActivity;
  final bool pole;
  final bool dtr;
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
    required this.showcase,
    required this.featuredActivity,
    required this.pole,
    required this.dtr,
    required this.onLevel,
    required this.onStation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final rungY = h * 0.58;
        final branchLeft = featuredActivity && index.isEven;
        final branchRight = featuredActivity && !index.isEven;
        final sideLeft = index.isEven;

        return Opacity(
          opacity: fog ? 0.42 : 1,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _GoldenLadderPainter(
                  branchLeft: branchLeft,
                  branchRight: branchRight,
                  rich: showcase,
                  fog: fog,
                ),
              ),
              if (pole)
                Positioned(
                  left: station != null && index.isEven ? null : 0,
                  right: station != null && index.isEven ? 0 : null,
                  bottom: 0,
                  child: const _FitMark(height: 76, child: Pole3D()),
                ),
              if (dtr)
                Positioned(
                  left: station != null && !index.isEven ? 0 : null,
                  right: station != null && !index.isEven ? null : 0,
                  bottom: 0,
                  child: const _FitMark(height: 68, child: DtrStation()),
                ),
              if (crest && !soon)
                Positioned(
                  right: 4,
                  top: 0,
                  child: const _FitMark(height: 34, child: ZeroDeathCrest()),
                ),
              Positioned(
                left: w / 2 - 24,
                top: rungY - 24,
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
                  left: sideLeft ? 2 : null,
                  right: sideLeft ? null : 2,
                  top: featuredActivity ? rungY - 46 : 8,
                  child: _StationPlaque(
                    station: station!,
                    lit: stationLit,
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

class _GoldenLadderPainter extends CustomPainter {
  final bool branchLeft;
  final bool branchRight;
  final bool rich;
  final bool fog;

  const _GoldenLadderPainter({
    required this.branchLeft,
    required this.branchRight,
    required this.rich,
    required this.fog,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0C1A2C));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF081422),
            rich ? const Color(0xFF16344C) : const Color(0xFF102033),
            rich ? const Color(0xFF1A4A34) : const Color(0xFF12263A),
          ],
        ).createShader(rect),
    );
    if (rich) {
      final terrace = Path()
        ..moveTo(0, h)
        ..lineTo(0, h * 0.55)
        ..quadraticBezierTo(w * 0.08, h * 0.36, w * 0.2, h)
        ..close();
      canvas.drawPath(terrace, Paint()..color = const Color(0xFF1C5A38));
      canvas.drawPath(
        terrace,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x663A8A58),
      );
      final far = Path()
        ..moveTo(w, h)
        ..lineTo(w, h * 0.48)
        ..quadraticBezierTo(w * 0.9, h * 0.3, w * 0.78, h)
        ..close();
      canvas.drawPath(far, Paint()..color = const Color(0xFF245C40));
    }

    const railW = 11.0;
    final span = w * 0.38;
    final gap = (span - railW) / 2;
    final leftX = w / 2 - gap;
    final rightX = w / 2 + gap;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(leftX - 10, 0, rightX + 14, h), const Radius.circular(12)),
      Paint()
        ..color = const Color(0x44040A12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    _rail(canvas, leftX, h);
    _rail(canvas, rightX, h);
    _rung(canvas, leftX, rightX, h * 0.58, fog);
    if (branchLeft) _branch(canvas, leftX, 16, h * 0.58 - 20, w);
    if (branchRight) _branch(canvas, rightX, w - 16, h * 0.58 - 20, w);
  }

  void _rail(Canvas canvas, double x, double h) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, h / 2), width: 11, height: h + 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(body.shift(const Offset(2.4, 0)), Paint()..color = const Color(0xFF3A280C));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF5C4212),
            Color(0xFFC6A15A),
            Color(0xFFFFF6D2),
            Color(0xFFE8C56A),
            Color(0xFF8A6420),
            Color(0xFF3A280C),
          ],
          stops: [0.0, 0.2, 0.42, 0.56, 0.8, 1.0],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x - 0.6, h / 2), width: 2.2, height: h),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF14915F),
    );
  }

  void _rung(Canvas canvas, double leftX, double rightX, double y, bool fog) {
    final rung = Rect.fromLTRB(leftX - 1, y - 4.5, rightX + 1, y + 4.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rung.shift(const Offset(1.6, 3)), const Radius.circular(4)),
      Paint()..color = const Color(0xFF2C1C08),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rung, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fog
              ? const [Color(0xFFD9C48A), Color(0xFF8A7040), Color(0xFF4A3818)]
              : const [Color(0xFFFFF8DC), Color(0xFFE6C56E), Color(0xFF8C6822), Color(0xFF4A3410)],
          stops: fog ? const [0.0, 0.55, 1.0] : const [0.0, 0.32, 0.7, 1.0],
        ).createShader(rung),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(rung.left + 6, rung.top + 1.1, rung.right - 6, rung.top + 2.4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xDDFFF8E6),
    );
    for (final x in [leftX, rightX]) {
      canvas.drawCircle(Offset(x, y), 4.6, Paint()..color = const Color(0xFFB8893A));
      canvas.drawCircle(Offset(x, y), 3.3, Paint()..color = const Color(0xFF0E7A4E));
      canvas.drawCircle(Offset(x - 0.8, y - 0.9), 1.15, Paint()..color = const Color(0xFFB6FFD8));
    }
  }

  void _branch(Canvas canvas, double fromX, double toX, double y, double w) {
    final path = Path()
      ..moveTo(fromX, y)
      ..lineTo(toX, y);
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2C1C08),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: const [Color(0xFF8A6420), Color(0xFFFFF3C8), Color(0xFFC6A15A)],
        ).createShader(Rect.fromLTWH(0, y - 8, w, 16)),
    );
  }

  @override
  bool shouldRepaint(covariant _GoldenLadderPainter oldDelegate) =>
      oldDelegate.branchLeft != branchLeft ||
      oldDelegate.branchRight != branchRight ||
      oldDelegate.rich != rich ||
      oldDelegate.fog != fog;
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
    final bronze = soon || (locked && !current);
    final asset = !bronze && current
        ? 'assets/duty_slip/world3d/coin_current_3d.webp'
        : !bronze && cleared
            ? 'assets/duty_slip/world3d/coin_cleared_3d.webp'
            : 'assets/duty_slip/world3d/medallion_bronze_3d.webp';
    final disc = Container(
      width: 48,
      height: 48,
      decoration: !bronze && (current || cleared)
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (current ? SlmColors.gold300 : SlmColors.emerald400)
                      .withValues(alpha: current ? 0.42 + 0.38 * glow : 0.22),
                  blurRadius: current ? 16 + 8 * glow : 8,
                  spreadRadius: current ? 1.4 : 0,
                ),
                if (current)
                  BoxShadow(
                    color: SlmColors.emerald400.withValues(alpha: 0.22 + 0.2 * glow),
                    blurRadius: 12,
                  ),
              ],
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            asset,
            width: 48,
            height: 48,
            cacheWidth: 140,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
          Text(
            '$number',
            style: zlText(16, weight: FontWeight.w900, color: SlmColors.ivory).copyWith(
              shadows: const [Shadow(color: Color(0xDD000000), offset: Offset(0, 1.2), blurRadius: 2)],
            ),
          ),
        ],
      ),
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

class _StationPlaque extends StatelessWidget {
  final _Station station;
  final bool lit;
  final double glow;
  final VoidCallback? onTap;

  const _StationPlaque({
    required this.station,
    required this.lit,
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
