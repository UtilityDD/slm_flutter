import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../home/lesson_progress_store.dart';
import '../home/lineman_progress.dart';
import '../shell/shell_providers.dart';
import '../training/training_provider.dart';
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

  const AdventureMap({
    super.key,
    required this.engine,
    required this.onOpen,
    required this.scrollOut,
    required this.muted,
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

enum _GiftFace { none, missed, active, upcoming, opened }

class _Flight {
  final int index;
  final _Station station;
  final bool large;

  const _Flight(this.index, this.station, this.large);
}

class _Reply {
  final String title;
  final String body;

  const _Reply(this.title, this.body);
}

const _tipHelmet = 'assets/duty_slip/world3d/prop_shield.webp';
const _tipGloves = 'assets/duty_slip/world3d/prop_ppe_gloves.webp';
const _tipHarness = 'assets/duty_slip/world3d/prop_ppe_harness.webp';
const _tipBoots = 'assets/duty_slip/world3d/prop_ppe_boots.webp';
const _tipVest = 'assets/duty_slip/world3d/prop_ppe_vest.webp';
const _tipLock = 'assets/duty_slip/world3d/prop_ppe_lock.webp';
const _tipRope = 'assets/duty_slip/world3d/prop_ppe_rope.webp';
const _tipCone = 'assets/duty_slip/world3d/prop_ppe_cone.webp';
const _tipGoggles = 'assets/duty_slip/world3d/prop_ppe_goggles.webp';

const _tipCycle = <String>[
  _tipHelmet,
  _tipGloves,
  _tipHarness,
  _tipBoots,
  _tipVest,
  _tipLock,
  _tipRope,
  _tipCone,
  _tipGoggles,
];

/// Safety-tip plaques follow the lesson on that rung: helmet, gloves, harness, and the rest of the kit.
String _tipAsset(int index) {
  final n = index + 1;
  return switch (n) {
    1 || 5 || 6 || 26 => _tipVest,
    2 => _tipHelmet,
    3 || 22 => _tipGloves,
    4 || 7 || 11 || 12 || 13 => _tipHarness,
    8 || 18 => _tipLock,
    9 || 14 => _tipCone,
    10 => _tipRope,
    15 || 16 || 20 => _tipHelmet,
    17 || 21 => _tipGoggles,
    19 => _tipBoots,
    _ => _tipCycle[index % _tipCycle.length],
  };
}

String _assetFor(_Station station, int index) => switch (station) {
      _Station.gift => 'assets/duty_slip/world3d/prop_chest.webp',
      _Station.hourly => 'assets/duty_slip/world3d/prop_clock.webp',
      _Station.identify => 'assets/duty_slip/world3d/prop_identify.webp',
      _Station.lesson => 'assets/duty_slip/world3d/prop_books.webp',
      _Station.life => 'assets/duty_slip/world3d/prop_tools.webp',
      _Station.tips => _tipAsset(index),
    };

class _AdventureMapState extends State<AdventureMap> with TickerProviderStateMixin {
  static const _rowH = 108.0;
  static const _path = 200;

  final _scroll = ScrollController();
  final _seen = <int>{};
  _Flight? _flight;
  _Reply? _reply;
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _ascent = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_publish);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _glow.repeat(reverse: true);
        _ascent.repeat();
      }
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
    _ascent.dispose();
    super.dispose();
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

  _GiftFace _giftFace(_Station? station, int index, int focus, bool soon) {
    if (station != _Station.gift) return _GiftFace.none;
    if (_seen.contains(index) && !soon) return _GiftFace.opened;
    if (soon || index > focus) return _GiftFace.upcoming;
    if (index < focus) return _GiftFace.missed;
    return _GiftFace.active;
  }

  void _present(_Station station, int index, {required bool large}) {
    if (_flight != null || _reply != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _openStation(station, index);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _flight = _Flight(index, station, large));
  }

  void _finishFlight() {
    final flight = _flight;
    if (!mounted || flight == null) return;
    setState(() => _flight = null);
    _openStation(flight.station, flight.index);
  }

  void _showKinetic({required String title, required String body, required bool speak}) {
    if (speak && !widget.muted) unawaited(DsVoice.play(body, muted: false));
    if (!mounted) return;
    setState(() => _reply = _Reply(title, enDigits(body)));
  }

  void _openStation(_Station station, int index) {
    HapticFeedback.lightImpact();
    if (index >= dsLevels.length) {
      _showKinetic(
        title: 'শীঘ্রই আসছে',
        body: 'এই ধাপটি এখনো খোলেনি।',
        speak: false,
      );
      return;
    }
    setState(() => _seen.add(index));
    switch (station) {
      case _Station.hourly:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuizPlayScreen()));
      case _Station.identify:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IdentifyQuizScreen()));
      case _Station.lesson:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrainingScreen()));
      case _Station.tips || _Station.life:
        _showKinetic(
          title: station == _Station.tips ? 'নিরাপত্তা টিপস' : 'লাইফ স্কিল কুইজ',
          body: dsBriefFor(dsLevels[index]).body,
          speak: true,
        );
      case _Station.gift:
        _showKinetic(
          title: 'সারপ্রাইজ গিফট',
          body: 'পরের ধাপগুলো খুললে এই বক্সে বিশেষ চ্যালেঞ্জ পাবেন।',
          speak: false,
        );
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
    final activityAt = <int>{};
    for (var n = focus; n < focus + 5 && n < live; n++) {
      if (_stationAt(n) != null) activityAt.add(n);
      if (activityAt.length == 2) break;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_glow, _ascent, _scroll]),
      builder: (context, _) {
        final glow = quiet ? 0.6 : _glow.value;
        final journey = (_path + 1) * _rowH;
        final light = (quiet ? 0.35 : _ascent.value) * journey;
        final view = _scroll.hasClients ? _scroll.position.viewportDimension : 640.0;
        final scrolled = _scroll.hasClients ? _scroll.offset : 0.0;
        final topInset = MediaQuery.paddingOf(context).top + 58;
        final bottomInset = MediaQuery.paddingOf(context).bottom + 18;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: AdventureWorld(scroll: _scroll, drift: _ascent, motion: !quiet)),
            ListView.builder(
                    controller: _scroll,
                    scrollDirection: Axis.vertical,
                    reverse: true,
                    physics: const ClampingScrollPhysics(),
                    clipBehavior: Clip.hardEdge,
                    itemCount: _path + 1,
                    itemExtent: _rowH,
                    padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
                    itemBuilder: (context, i) {
                      final cap = i == _path;
                      final soon = !cap && i >= live;
                      final fog = !cap && i > focus + 3;
                      final station = cap ? null : _stationAt(i);
                      final rested = station != null && !soon && (i < focus || _seen.contains(i));
                      final fresh = station != null && !soon && !fog && !rested && station != _Station.gift;
                      final giftFace = _giftFace(station, i, focus, soon);
                      final fromBottom = bottomInset + i * _rowH + _rowH / 2 - scrolled;
                      final dist = (((view - fromBottom) / view) - 0.5).abs().clamp(0.0, 0.5) * 2;
                      final closeness = 1 - dist;
                      final zoom = quiet || station == null ? 1.0 : 0.34 + 1.2 * closeness * closeness;
                      final number = cap ? _path : (soon ? i + 1 : dsLevels[i].number);
                      final gleamY = _rowH - (light - i * _rowH);
                      return _MapBand(
                        index: i,
                        number: number,
                        soon: soon,
                        fog: fog,
                        cap: cap,
                        cleared: !soon && !cap && (i < focus || (e.bestRank[i] != null && e.bestRank[i] != DsLevelRank.again)),
                        current: !soon && !cap && i == focus,
                        locked: !cap && (soon || i > focus),
                        glow: glow,
                        station: station,
                        fresh: fresh,
                        rested: rested,
                        giftFace: giftFace,
                        zoom: zoom,
                        hidden: _flight?.index == i,
                        featuredActivity: activityAt.contains(i),
                        motion: !quiet,
                        gleamY: gleamY,
                        onLevel: cap
                            ? () {
                                HapticFeedback.selectionClick();
                                unawaited(_showSheet(
                                  title: 'মৃত্যুহীন লক্ষ্য',
                                  body: 'পথের শেষ। 200 ধাপ পেরিয়ে মৃত্যুঝুঁকি শূন্য রাখাই এই লক্ষ্য।',
                                  speak: false,
                                ));
                              }
                            : soon
                                ? () {
                                    HapticFeedback.selectionClick();
                                    unawaited(_showSheet(
                                      title: 'শীঘ্রই আসছে',
                                      body: 'এই ধাপটি এখনো খোলেনি।',
                                      speak: false,
                                    ));
                                  }
                                : () => _openLevel(i),
                        onStation: station == null
                            ? null
                            : () => _present(
                                  station,
                                  i,
                                  large: station == _Station.gift && giftFace == _GiftFace.active,
                                ),
                      );
                    },
                  ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66050A16), Color(0x00050A16)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                  child: _TopHeader(
                    engine: e,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: IgnorePointer(
                child: SizedBox(
                  width: 86,
                  height: 118,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: 2,
                        child: Container(
                          width: 62,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.elliptical(62, 12)),
                            color: const Color(0xCC061008),
                            boxShadow: const [BoxShadow(color: Color(0xAA061008), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        top: 0,
                        child: Transform.translate(
                          offset: Offset(0, quiet ? 0 : -1.2 * glow),
                          child: const FittedBox(alignment: Alignment.bottomCenter, child: CornerLineman()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_flight != null)
              Positioned.fill(
                child: _ObjectReveal(
                  asset: _assetFor(_flight!.station, _flight!.index),
                  endScale: _flight!.large ? 2.2 : 1.45,
                  onDone: _finishFlight,
                ),
              ),
            if (_reply != null)
              Positioned.fill(
                child: _KineticReply(
                  title: _reply!.title,
                  body: _reply!.body,
                  still: quiet,
                  onClose: () => setState(() => _reply = null),
                ),
              ),
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
  final Widget child;

  const _GoldShell({
    required this.radius,
    this.rim = 1.25,
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
        decoration: BoxDecoration(
          gradient: SlmGradients.navyCard,
          borderRadius: BorderRadius.circular(inner),
        ),
        child: child,
      ),
    );
  }
}

class _TopHeader extends ConsumerWidget {
  final DutySlipEngine engine;
  final VoidCallback onBack;

  const _TopHeader({required this.engine, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final profile = ref.watch(authProvider).profile;
    final localDone = ref.watch(allCompletedLessonsProvider);
    final ladder = ref.watch(trainingLadderProvider).value;
    var highestDone = 0;
    if (ladder != null) {
      for (final m in ladder) {
        if (!m.isCompleted) break;
        highestDone = m.moduleNumber;
      }
    }
    final path = linemanPath(
      profile,
      extraCompleted: localDone,
      highestCompletedModule: highestDone > 0 ? highestDone : null,
    );
    final rank = linemanBadgeName(path.achieved == 0 ? 1 : path.achieved, bn);
    final calm = engine.totalCumulativeDanger == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 10),
          _RankPill(label: rank),
          const Spacer(),
          _ScoreChip(mark: '◆', value: enDigits('${engine.totalCumulativeScore}'), color: SlmColors.gold200),
          const SizedBox(width: 8),
          _ScoreChip(
            mark: '💀',
            value: enDigits('${engine.totalCumulativeDanger}'),
            color: calm ? SlmColors.emerald300 : SlmColors.danger,
          ),
        ],
      ),
    );
  }
}

class _RankPill extends StatelessWidget {
  final String label;

  const _RankPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
        color: const Color(0xB3050A16),
      ),
      child: Text(label, style: zlText(12, weight: FontWeight.w800, color: SlmColors.gold200, height: 1.1)),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String mark;
  final String value;
  final Color color;

  const _ScoreChip({required this.mark, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xB3050A16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$mark  $value', style: zlText(14, weight: FontWeight.w800, color: color, height: 1.1)),
    );
  }
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

class _MapBand extends StatelessWidget {
  final int index;
  final int number;
  final bool soon;
  final bool fog;
  final bool cap;
  final bool cleared;
  final bool current;
  final bool locked;
  final double glow;
  final _Station? station;
  final bool fresh;
  final bool rested;
  final _GiftFace giftFace;
  final double zoom;
  final bool hidden;
  final bool featuredActivity;
  final bool motion;
  final double gleamY;
  final VoidCallback? onLevel;
  final VoidCallback? onStation;

  const _MapBand({
    required this.index,
    required this.number,
    required this.soon,
    required this.fog,
    required this.cap,
    required this.cleared,
    required this.current,
    required this.locked,
    required this.glow,
    required this.station,
    required this.fresh,
    required this.rested,
    required this.giftFace,
    required this.zoom,
    required this.hidden,
    required this.featuredActivity,
    required this.motion,
    required this.gleamY,
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
        final gift = station == _Station.gift;
        final sideLeft = gift ? (index ~/ 8).isEven : index.isEven;
        final stationTop = gift ? const [0.0, 8.0, 16.0][(index ~/ 8) % 3] : 2.0 + (index % 3) * 4.0;

        if (cap) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _GoldenLadderPainter(
                  branchLeft: false,
                  branchRight: false,
                  fog: false,
                  gleamY: gleamY,
                  cap: true,
                ),
              ),
              Center(
                child: _FinishMark(glow: glow, motion: motion, onTap: onLevel),
              ),
            ],
          );
        }

        return Opacity(
          opacity: fog ? 0.42 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _GoldenLadderPainter(
                  branchLeft: branchLeft,
                  branchRight: branchRight,
                  fog: fog,
                  gleamY: gleamY,
                ),
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
              if (station != null && !hidden)
                Positioned(
                  left: sideLeft ? 4 : null,
                  right: sideLeft ? null : 4,
                  top: stationTop,
                  child: Transform.scale(
                    scale: zoom,
                    alignment: Alignment.center,
                    child: _StationPlaque(
                      station: station!,
                      asset: _assetFor(station!, index),
                      glow: glow,
                      fresh: fresh,
                      rested: rested,
                      giftFace: giftFace,
                      motion: motion,
                      onTap: onStation,
                    ),
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
  final bool fog;
  final double gleamY;
  final bool cap;

  const _GoldenLadderPainter({
    required this.branchLeft,
    required this.branchRight,
    required this.fog,
    required this.gleamY,
    this.cap = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const railW = 11.0;
    final span = w * 0.38;
    final gap = (span - railW) / 2;
    final leftX = w / 2 - gap;
    final rightX = w / 2 + gap;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(leftX - 8, 0, rightX + 12, h), const Radius.circular(12)),
      Paint()
        ..color = const Color(0x33040A12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    _rail(canvas, leftX, h);
    _rail(canvas, rightX, h);
    if (!cap) {
      _rung(canvas, leftX, rightX, h * 0.58, fog);
      if (branchLeft) _branch(canvas, leftX, 18, h * 0.58 - 20, w);
      if (branchRight) _branch(canvas, rightX, w - 18, h * 0.58 - 20, w);
    }
    if (gleamY > -28 && gleamY < h + 28) {
      for (final x in [leftX, rightX]) {
        canvas.drawCircle(
          Offset(x, gleamY),
          14,
          Paint()
            ..color = const Color(0x88FFF3C4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
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
      oldDelegate.fog != fog ||
      oldDelegate.gleamY != gleamY ||
      oldDelegate.cap != cap;
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
  final String asset;
  final double glow;
  final bool fresh;
  final bool rested;
  final _GiftFace giftFace;
  final bool motion;
  final VoidCallback? onTap;

  const _StationPlaque({
    required this.station,
    required this.asset,
    required this.glow,
    required this.fresh,
    required this.rested,
    required this.giftFace,
    required this.motion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chest = station == _Station.gift;
    final active = giftFace == _GiftFace.active;
    final missed = giftFace == _GiftFace.missed;
    final lively = motion && (active || (giftFace == _GiftFace.none && fresh));
    final turn = lively ? glow : 0.2;
    final bob = lively
        ? switch (station) {
            _Station.gift => -5 * turn,
            _Station.identify => -2.2 * turn,
            _Station.lesson => -1.6 * turn,
            _ => -1.2 * turn,
          }
        : 0.0;
    final tilt = motion && fresh && station == _Station.life ? (turn - 0.5) * 0.1 : 0.0;
    final picture = Image.asset(
      asset,
      width: 96,
      height: 84,
      cacheWidth: 280,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    final dull = rested || giftFace == _GiftFace.opened;
    final art = missed
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.62, 0.2, 0.08, 0, 6,
              0.16, 0.55, 0.08, 0, 6,
              0.1, 0.16, 0.48, 0, 4,
              0, 0, 0, 1, 0,
            ]),
            child: picture,
          )
        : dull
            ? ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.45, 0.28, 0.12, 0, 10,
                  0.18, 0.42, 0.12, 0, 10,
                  0.12, 0.2, 0.38, 0, 8,
                  0, 0, 0, 1, 0,
                ]),
                child: picture,
              )
            : picture;

    final body = Opacity(
      opacity: missed ? 0.78 : dull ? 0.62 : 1,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Transform.rotate(
          angle: tilt,
          child: SizedBox(
            width: 96,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x66FFE7A3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xCCFFD56A).withValues(alpha: 0.55 + 0.35 * turn),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                art,
                if (station == _Station.hourly && fresh)
                  Align(
                    alignment: const Alignment(0, -0.16),
                    child: CustomPaint(size: const Size(22, 22), painter: _ClockPainter(turn)),
                  ),
                if (chest && motion && active)
                  CustomPaint(size: const Size(96, 84), painter: _SparkPainter(turn)),
              ],
            ),
          ),
        ),
      ),
    );

    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: body,
    );
  }
}

class _FinishMark extends StatelessWidget {
  final double glow;
  final bool motion;
  final VoidCallback? onTap;

  const _FinishMark({required this.glow, required this.motion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pulse = motion ? glow : 0.65;
    final mark = Transform.scale(
      scale: motion ? 1 + 0.06 * pulse : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.lerp(const Color(0xFFE8C56B), const Color(0xFF3DDC97), pulse)!.withValues(alpha: 0.72),
              blurRadius: 22 + 12 * pulse,
              spreadRadius: 2 + pulse,
            ),
          ],
        ),
        child: AnimatedSafetyShield(size: 78, animate: motion, entrance: false),
      ),
    );
    return SlmTactile(
      onTap: onTap,
      builder: (context, press, child) => Transform.scale(scale: 1 - 0.05 * press, child: child),
      child: mark,
    );
  }
}

class _ObjectReveal extends StatefulWidget {
  final String asset;
  final double endScale;
  final VoidCallback onDone;

  const _ObjectReveal({required this.asset, required this.endScale, required this.onDone});

  @override
  State<_ObjectReveal> createState() => _ObjectRevealState();
}

class _ObjectRevealState extends State<_ObjectReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _move.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _move,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_move.value);
        final scale = 0.28 + (widget.endScale - 0.28) * t;
        return Stack(
          children: [
            ModalBarrier(
              color: Colors.black.withValues(alpha: 0.46 * t),
              dismissible: false,
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 120),
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD56A).withValues(alpha: 0.15 + 0.4 * t),
                          blurRadius: widget.endScale > 1.8 ? 28 : 16,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      widget.asset,
                      width: 96,
                      height: 84,
                      cacheWidth: 320,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
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

class _KineticReply extends StatefulWidget {
  final String title;
  final String body;
  final bool still;
  final VoidCallback onClose;

  const _KineticReply({
    required this.title,
    required this.body,
    required this.still,
    required this.onClose,
  });

  @override
  State<_KineticReply> createState() => _KineticReplyState();
}

class _KineticReplyState extends State<_KineticReply> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 980),
  );

  @override
  void initState() {
    super.initState();
    if (widget.still) {
      _play.value = 1;
    } else {
      _play.forward();
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleWords = widget.title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final bodyWords = widget.body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return GestureDetector(
      onTap: widget.onClose,
      child: ColoredBox(
        color: const Color(0xB3060C16),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedBuilder(
              animation: _play,
              builder: (context, _) {
                final count = titleWords.length + bodyWords.length;
                final step = count <= 1 ? 0.0 : 0.62 / (count - 1);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _KineticLine(
                      words: titleWords,
                      clock: _play,
                      start: 0,
                      step: step,
                      style: zlText(28, weight: FontWeight.w900, color: SlmColors.gold100, height: 1.15),
                    ),
                    const SizedBox(height: 14),
                    _KineticLine(
                      words: bodyWords,
                      clock: _play,
                      start: titleWords.length,
                      step: step,
                      style: zlText(16, weight: FontWeight.w600, color: SlmColors.ivory, height: 1.45),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _KineticLine extends StatelessWidget {
  final List<String> words;
  final Animation<double> clock;
  final int start;
  final double step;
  final TextStyle style;

  const _KineticLine({
    required this.words,
    required this.clock,
    required this.start,
    required this.step,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 4,
      children: [
        for (var i = 0; i < words.length; i++)
          _KineticWord(
            word: words[i],
            clock: clock,
            index: start + i,
            step: step,
            style: style,
          ),
      ],
    );
  }
}

class _KineticWord extends StatelessWidget {
  final String word;
  final Animation<double> clock;
  final int index;
  final double step;
  final TextStyle style;

  const _KineticWord({
    required this.word,
    required this.clock,
    required this.index,
    required this.step,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final begin = (index * step).clamp(0.0, 0.72);
    final t = Interval(begin, (begin + 0.28).clamp(begin + 0.01, 1.0), curve: Curves.easeOutCubic).transform(clock.value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 16),
        child: Text(word, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final double turn;

  const _SparkPainter(this.turn);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color.fromRGBO(255, 236, 180, 0.25 + 0.55 * turn);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.18), 1.4, paint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.28), 1.1, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.turn != turn;
}

class _ClockPainter extends CustomPainter {
  final double turn;

  const _ClockPainter(this.turn);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawLine(
      c,
      c + Offset(math.cos(turn * math.pi * 2 - 1.2) * 7, math.sin(turn * math.pi * 2 - 1.2) * 7),
      Paint()
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1A2744),
    );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) => oldDelegate.turn != turn;
}

