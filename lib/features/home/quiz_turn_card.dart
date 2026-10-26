import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Question face that Y-flips when [turnKey] changes.
class QuizTurnCard extends StatefulWidget {
  final Object turnKey;
  final Widget child;
  final Color paper;
  final Color ink;
  final Color accent;
  final VoidCallback? onFlipStart;

  const QuizTurnCard({
    super.key,
    required this.turnKey,
    required this.child,
    required this.paper,
    required this.ink,
    required this.accent,
    this.onFlipStart,
  });

  @override
  State<QuizTurnCard> createState() => _QuizTurnCardState();
}

class _QuizTurnCardState extends State<QuizTurnCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Widget _front;
  Widget? _pending;
  Object? _shownKey;
  bool _swapped = false;

  @override
  void initState() {
    super.initState();
    _front = widget.child;
    _shownKey = widget.turnKey;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(_onTick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _ctrl.value = 0;
          _swapped = false;
          _pending = null;
        }
      });
  }

  void _onTick() {
    if (!_swapped && _ctrl.value >= 0.5 && _pending != null) {
      _swapped = true;
      setState(() {
        _front = _pending!;
        _shownKey = widget.turnKey;
      });
    }
  }

  @override
  void didUpdateWidget(covariant QuizTurnCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.turnKey != _shownKey) {
      _pending = widget.child;
      _swapped = false;
      widget.onFlipStart?.call();
      _ctrl.forward(from: 0);
    } else if (_ctrl.isDismissed || _ctrl.isCompleted) {
      _front = widget.child;
    } else {
      _pending = widget.child;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_ctrl.value);
        final angle = t * math.pi;
        final showBack = angle > math.pi / 2;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _CardShell(
                    paper: widget.paper,
                    ink: widget.ink,
                    accent: widget.accent,
                    child: _BackFace(accent: widget.accent),
                  ),
                )
              : _CardShell(
                  paper: widget.paper,
                  ink: widget.ink,
                  accent: widget.accent,
                  child: _front,
                ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final Color paper;
  final Color ink;
  final Color accent;

  const _CardShell({
    required this.child,
    required this.paper,
    required this.ink,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22), width: 1.4),
        boxShadow: [
          BoxShadow(color: ink.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
          BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

class _BackFace extends StatelessWidget {
  final Color accent;

  const _BackFace({required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.45), width: 2),
            color: accent.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: accent, size: 28),
        ),
      ),
    );
  }
}

/// Brief fan/deal stack shown while the quiz is preparing.
class QuizDealSplash extends StatefulWidget {
  final String label;
  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color accent;
  final Color softInk;

  const QuizDealSplash({
    super.key,
    required this.label,
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.accent,
    required this.softInk,
  });

  @override
  State<QuizDealSplash> createState() => _QuizDealSplashState();
}

class _QuizDealSplashState extends State<QuizDealSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 120,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translateByDouble(
                            math.sin((t + i * 0.22) * math.pi * 2) * (10.0 + i * 4),
                            -i * 4.0 + math.cos((t + i * 0.18) * math.pi * 2) * 3,
                            0,
                            1,
                          )
                          ..rotateZ((-0.12 + i * 0.12) + math.sin(t * math.pi * 2 + i) * 0.06),
                        child: Container(
                          width: 88,
                          height: 112,
                          decoration: BoxDecoration(
                            color: i == 1 ? widget.paper : widget.paperDeep,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: widget.accent.withValues(alpha: 0.35), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: widget.ink.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.style_rounded,
                              color: widget.accent.withValues(alpha: 0.55 + i * 0.1),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: banglaFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.softInk,
            ),
          ),
        ],
      ),
    );
  }
}
