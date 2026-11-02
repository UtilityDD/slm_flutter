import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';
import '../training/training_provider.dart';
import '../duty_slip/duty_slip_page.dart';
import '../duty_slip/duty_slip_models.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'lesson_progress_store.dart';
import 'lineman_figure.dart';
import 'lineman_progress.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _score = 0;
  int _deaths = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBoard());
  }

  /// Same numbers the ladder already saves. Not a new score.
  Future<void> _loadBoard() async {
    final prefs = await SharedPreferences.getInstance();
    final score = prefs.getInt('ds_career_score') ?? 0;
    final ranks = prefs.getStringList('ds_best_ranks') ?? const <String>[];
    final danger = prefs.getStringList('ds_danger_counts') ?? const <String>[];
    var deaths = 0;
    final n = math.min(ranks.length, danger.length);
    for (var i = 0; i < n; i++) {
      if (ranks[i].isEmpty) continue;
      final d = int.tryParse(danger[i]);
      if (d != null && d > 0) deaths += d;
    }
    if (!mounted) return;
    setState(() {
      _score = score;
      _deaths = deaths;
    });
  }

  Future<void> _openPath(Rect? sourceRect) async {
    await DutySlipPage.open(context, sourceRect: sourceRect);
    await _loadBoard();
  }

  void _openToolbox() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SlmColors.navy900,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final bn = ref.watch(languageProvider);
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewPaddingOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr(bn, 'টুলবক্স', 'Toolbox'), style: _ivory(16, FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LangChoice(
                        label: 'বাংলা',
                        selected: bn,
                        onTap: () => ref.read(languageProvider.notifier).setBengali(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LangChoice(
                        label: 'English',
                        selected: !bn,
                        onTap: () => ref.read(languageProvider.notifier).setBengali(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ToolRow(
                  icon: Icons.phone_in_talk_rounded,
                  label: tr(bn, 'জরুরি নম্বর', 'Emergency'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(this.context).pushNamed(AppRoutes.emergency);
                  },
                ),
                _ToolRow(
                  icon: Icons.visibility_rounded,
                  label: tr(bn, 'পরিচিতি', 'Identify'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(shellTabProvider.notifier).select(1);
                  },
                ),
                _ToolRow(
                  icon: Icons.tune_rounded,
                  label: tr(bn, 'সেটিংস', 'Settings'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(this.context).pushNamed(AppRoutes.more);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
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
    final guest = auth.isGuest || !auth.isAuthenticated;
    final verified = linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final fullName = profile?.fullName?.trim() ?? '';
    final slmId = profile?.slmId?.trim() ?? '';
    final guestLabel = tr(bn, 'অতিথি', 'Guest');
    final name = guest
        ? guestLabel
        : (fullName.isNotEmpty
              ? fullName
              : (slmId.isNotEmpty ? slmId : guestLabel));
    final rank = linemanBadgeName(path.achieved == 0 ? 1 : path.achieved, bn);
    final quiet = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Theme(
              data: SlmTheme.night(),
              child: const SlmBackground(constrain: false, child: SizedBox.expand()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Face(url: guest ? null : profile?.avatarUrl, name: name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        guest ? AppRoutes.login : AppRoutes.more,
                                      );
                                    },
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _ivory(22, FontWeight.w800),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                if (!verified)
                                  GestureDetector(
                                    onTap: () => showVerifySheet(context),
                                    child: const VerifyTick(gold: false, size: 18),
                                  )
                                else
                                  const VerifyTick(gold: true, size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _RankPill(label: rank),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ToolboxButton(onTap: _openToolbox),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreChip(
                          mark: '◆',
                          value: enDigits('$_score'),
                          color: SlmColors.gold200,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ScoreChip(
                          mark: '💀',
                          value: enDigits('$_deaths'),
                          color: _deaths == 0 ? SlmColors.emerald300 : SlmColors.danger,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 280,
                          child: _RankPeek(
                            step: path.achieved.clamp(0, 10),
                            bn: bn,
                            motion: !quiet,
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.elliptical(120, 14)),
                            color: const Color(0xCC061008),
                            boxShadow: const [BoxShadow(color: Color(0xAA061008), blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PathPlayChip(
                    label: 'মৃত্যুহীন পথ',
                    onTap: (sourceRect) => unawaited(_openPath(sourceRect)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankPeek extends StatefulWidget {
  final int step;
  final bool bn;
  final bool motion;

  const _RankPeek({required this.step, required this.bn, required this.motion});

  @override
  State<_RankPeek> createState() => _RankPeekState();
}

class _RankPeekState extends State<_RankPeek> with SingleTickerProviderStateMixin {
  double _page = 0;
  double _from = 0;
  int _crossed = 0;
  bool _dragging = false;
  late final AnimationController _back;

  @override
  void initState() {
    super.initState();
    _crossed = widget.step;
    _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))..addListener(_onSpring);
  }

  @override
  void didUpdateWidget(_RankPeek oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _back.stop();
      _page = 0;
      _crossed = widget.step;
    }
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _onSpring() {
    if (!mounted) return;
    setState(() => _page = _from * (1 - Curves.easeOutCubic.transform(_back.value)));
  }

  void _returnHome() {
    if (!widget.motion || _page.abs() < 0.02) {
      setState(() => _page = 0);
      return;
    }
    _from = _page;
    final ms = (240 + 70 * _page.abs()).round().clamp(240, 520);
    _back.duration = Duration(milliseconds: ms);
    _back.forward(from: 0);
  }

  String _lookName(int step) {
    if (step <= 0) return widget.bn ? 'শুরু' : 'Start';
    return linemanBadgeName(step, widget.bn);
  }

  @override
  Widget build(BuildContext context) {
    final nearest = (widget.step + _page).round().clamp(0, 10);
    final peeking = nearest != widget.step;
    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragging = true;
          _back.stop();
        },
        onHorizontalDragUpdate: (d) {
          final width = context.size?.width ?? 1;
          final span = width < 1 ? 1.0 : width;
          final min = -widget.step.toDouble();
          final max = (10 - widget.step).toDouble();
          var next = _page - d.delta.dx / span;
          if (next < min || next > max) {
            final edge = next.clamp(min, max);
            next = edge + (next - edge) * 0.22;
          }
          setState(() => _page = next);
          final shown = (widget.step + _page).round().clamp(0, 10);
          if (_dragging && shown != _crossed) {
            _crossed = shown;
            HapticFeedback.selectionClick();
          }
        },
        onHorizontalDragEnd: (_) {
          _dragging = false;
          _returnHome();
        },
        onHorizontalDragCancel: () {
          _dragging = false;
          _returnHome();
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            for (final i in _visibleSteps()) _slot(i),
            Positioned(
              top: 2,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: peeking ? 1 : 0,
                  duration: Duration(milliseconds: widget.motion ? 140 : 0),
                  child: Text(
                    _lookName(nearest),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ivory(13, FontWeight.w700).copyWith(color: SlmColors.ivory.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _visibleSteps() {
    final center = widget.step + _page;
    final steps = <int>[
      for (var i = 0; i <= 10; i++)
        if ((i - center).abs() < 1.15) i,
    ];
    steps.sort((a, b) => (b - center).abs().compareTo((a - center).abs()));
    return steps;
  }

  Widget _slot(int step) {
    final dist = (step - (widget.step + _page)).abs();
    final mine = step == widget.step;
    final opacity = mine ? (1 - dist * 0.45).clamp(0.55, 1.0) : 1.0;
    return LayoutBuilder(
      builder: (context, box) {
        return Transform.translate(
          offset: Offset((step - (widget.step + _page)) * box.maxWidth, 0),
          child: Opacity(
            opacity: opacity,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LinemanFigure(
                step: step,
                quiet: !mine,
                enableHero: widget.motion && mine && _page.abs() < 0.02,
              ),
            ),
          ),
        );
      },
    );
  }
}

TextStyle _ivory(double size, FontWeight weight) => TextStyle(
      fontFamily: banglaFont,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      color: SlmColors.ivory,
    );

class _Face extends StatelessWidget {
  final String? url;
  final String name;

  const _Face({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? 'ল' : name.characters.first;
    final photo = url != null && url!.startsWith('http');
    return CircleAvatar(
      radius: 18,
      backgroundColor: SlmColors.navy800,
      backgroundImage: photo ? NetworkImage(url!) : null,
      child: photo
          ? null
          : Text(initial, style: _ivory(14, FontWeight.w700)),
    );
  }
}

class _RankPill extends StatelessWidget {
  final String label;

  const _RankPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
        color: SlmColors.navy950.withValues(alpha: 0.35),
      ),
      child: Text(label, style: _ivory(11, FontWeight.w700).copyWith(color: SlmColors.gold200, height: 1.1)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: SlmColors.navy950.withValues(alpha: 0.42),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$mark  $value',
        textAlign: TextAlign.center,
        style: _ivory(16, FontWeight.w800).copyWith(color: color),
      ),
    );
  }
}

class _ToolboxButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ToolboxButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: 'টুলবক্স',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6)),
          color: SlmColors.navy950.withValues(alpha: 0.45),
        ),
        child: const Icon(Icons.apps_rounded, size: 18, color: SlmColors.gold200),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: SlmColors.gold200, size: 22),
            const SizedBox(width: 12),
            Text(label, style: _ivory(16, FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PathPlayChip extends StatefulWidget {
  final String label;
  final void Function(Rect? sourceRect) onTap;

  const _PathPlayChip({required this.label, required this.onTap});

  @override
  State<_PathPlayChip> createState() => _PathPlayChipState();
}

class _PathPlayChipState extends State<_PathPlayChip>
    with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _charge;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    unawaited(DsPack.load());
    _charge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _charge.dispose();
    _shine.dispose();
    super.dispose();
  }

  void _trigger(BuildContext ctx) {
    if (_charge.isAnimating) return;
    HapticFeedback.heavyImpact();
    unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.95));
    final box = ctx.findRenderObject() as RenderBox?;
    final rect = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;
    _charge.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _pressed = false);
      widget.onTap(rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (chipContext) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => _trigger(chipContext),
        child: AnimatedBuilder(
          animation: _charge,
          builder: (context, child) {
            final chargeVal = _charge.value;
            final chargeScale = 1.0 + (math.sin(chargeVal * math.pi) * 0.08);

            return Transform.translate(
              offset: Offset(0, _pressed ? 2 : 0),
              child: Transform.scale(
                scale: (_pressed ? 0.97 : 1) * chargeScale,
                child: child,
              ),
            );
          },
          child: Semantics(
            button: true,
            label: widget.label,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = math.min(_PathBadge.width, box.maxWidth);
                return SizedBox(
                  width: w,
                  height: w * _PathBadge.aspect,
                  child: _PathBadge(
                    shine: _shine,
                    charge: _charge,
                    pressed: _pressed,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Shield emblem riding on an emerald pill with the title and a gold arrow.
/// Keeps the footprint of the old 270 px artwork (560 × 174).
class _PathBadge extends StatelessWidget {
  static const width = 270.0;
  static const aspect = 174 / 560;

  final Animation<double> shine;
  final Animation<double> charge;
  final bool pressed;

  const _PathBadge({
    required this.shine,
    required this.charge,
    required this.pressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final inset = h * 0.13;
        final pillH = h - inset * 2;
        final shield = h * 1.32;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: h * 0.36,
              right: 0,
              top: inset,
              bottom: inset,
              child: AnimatedBuilder(
                animation: Listenable.merge([shine, charge]),
                builder: (context, _) => _pill(pillH, h * 0.6),
              ),
            ),
            Positioned(
              left: -h * 0.24,
              top: (h - shield) / 2 - h * 0.02,
              width: shield,
              height: shield,
              child: IgnorePointer(
                child: AnimatedSafetyShield(size: shield, intensity: 0.85),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pill(double pillH, double textStart) {
    // The band crosses in the first 45% of each loop, then rests.
    final run = (shine.value / 0.45).clamp(0.0, 1.0);
    final pass = Curves.easeInOutSine.transform(run);
    final boost = math.sin(charge.value * math.pi);
    final radius = BorderRadius.circular(pillH / 2);
    final title = TextStyle(
      fontFamily: banglaFont,
      fontSize: pillH * 0.42,
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: SlmColors.ivory,
      shadows: const [
        Shadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2)),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SlmColors.gold200,
            SlmColors.gold500,
            SlmColors.gold700,
            SlmColors.gold300,
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: SlmColors.emerald500.withValues(alpha: 0.28 + 0.32 * boost),
            blurRadius: 18 + 10 * boost,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: pressed ? 0.25 : 0.4),
            blurRadius: pressed ? 6 : 12,
            offset: Offset(0, pressed ? 2 : 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SlmSweepMask(
          t: pass,
          intensity: 0.9,
          color: const Color(0xFFFFF6D6),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E7A5E), SlmColors.emerald800, Color(0xFF04281F)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.48,
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(textStart, 0, pillH * 0.1, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'মৃত্যুহীন '),
                                TextSpan(
                                  text: 'পথ',
                                  style: title.copyWith(color: SlmColors.gold300),
                                ),
                              ],
                            ),
                            style: title,
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                          ),
                        ),
                      ),
                      SizedBox(width: pillH * 0.08),
                      _PathArrow(size: pillH * 0.74, phase: shine.value),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PathArrow extends StatelessWidget {
  final double size;
  final double phase;

  const _PathArrow({required this.size, required this.phase});

  @override
  Widget build(BuildContext context) {
    final nudge = math.sin(phase * 2 * math.pi) * 1.6;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [SlmColors.gold100, SlmColors.gold300, SlmColors.gold600],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: SlmColors.gold700, width: 1),
        boxShadow: [
          BoxShadow(
            color: SlmColors.gold400.withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
      child: Transform.translate(
        offset: Offset(1 + nudge, 0),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          size: size * 0.42,
          color: SlmColors.navy900,
        ),
      ),
    );
  }
}

class _LangChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChoice({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected ? SlmGradients.gold : null,
          color: selected ? null : SlmColors.navy950.withValues(alpha: 0.45),
          border: Border.all(color: selected ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: banglaFont,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: selected ? SlmColors.navy900 : SlmColors.ivory,
          ),
        ),
      ),
    );
  }
}
