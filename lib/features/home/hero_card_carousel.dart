import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/dev_unlock.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'hero_card.dart';
import 'lesson_progress_store.dart';
import 'level_celebration_page.dart';
import 'level_lessons_sheet.dart';
import 'lineman_progress.dart';

String heroTitle(int step, bool bn) {
  if (step <= 0) return bn ? 'শুরু' : 'Start';
  final c = linemanChapters[(step - 1).clamp(0, linemanChapters.length - 1)];
  return bn ? c.$1 : c.$2;
}

/// Swipeable deck of level cards with flip-in, tilt and sheen.
class HeroCardCarousel extends ConsumerStatefulWidget {
  final LinemanPath path;
  final bool bn;

  const HeroCardCarousel({super.key, required this.path, required this.bn});

  @override
  ConsumerState<HeroCardCarousel> createState() => _HeroCardCarouselState();
}

class _HeroCardCarouselState extends ConsumerState<HeroCardCarousel>
    with TickerProviderStateMixin {
  static const _last = 10;

  late final PageController _pages;
  late final AnimationController _intro;
  late final AnimationController _sheen;
  late int _page;
  Offset _tilt = Offset.zero;
  bool _ready = false;
  bool _opening = false;
  bool _openScrollDone = false;

  @override
  void initState() {
    super.initState();
    // Open on the Start card, then glide to the current reading level.
    _page = 0;
    _pages = PageController(initialPage: 0, viewportFraction: 0.8);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _intro.forward().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _sheen.repeat();
      _consumePendingReveal();
    });
  }

  /// Present reading level = next level after the last consecutively completed
  /// one. Computed from live providers so it is correct once data has loaded.
  int _presentReadingLevel() {
    final completed = ref.read(allCompletedLessonsProvider);
    if (!isPathOrientationDone(completed)) return 0;
    final ladder =
        ref.read(trainingLadderProvider).value ?? const <TrainingModuleItem>[];
    var highestDone = 0;
    for (final m in ladder) {
      if (!m.isCompleted) break;
      highestDone = m.moduleNumber;
    }
    return (highestDone + 1).clamp(0, _last);
  }

  /// On launch, dwell on the Start card, then smoothly glide to the current level.
  void _scrollToReadingLevel() {
    if (!mounted || !_pages.hasClients) return;
    if (ref.read(pendingHomeRevealStepProvider) != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pages.hasClients) return;
      // Dwell on the Start card so it clearly reads, then a slow, deliberate glide.
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted || !_pages.hasClients) return;
      // Recompute now that data has settled.
      final target = _presentReadingLevel();
      if (target == _page) return;
      final distance = (target - _page).abs();
      final ms = (500 + distance * 240).clamp(900, 2400);
      await _pages.animateToPage(
        target,
        duration: Duration(milliseconds: ms),
        curve: Curves.easeInOutCubic,
      );
      if (mounted) setState(() => _page = target);
    });
  }

  @override
  void didUpdateWidget(covariant HeroCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consumePendingReveal();
  }

  void _consumePendingReveal() {
    final pending = ref.read(pendingHomeRevealStepProvider);
    if (pending == null || !_pages.hasClients) return;
    ref.read(pendingHomeRevealStepProvider.notifier).setStep(null);
    final target = pending.clamp(0, _last);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pages.hasClients) return;
      await _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      if (mounted) setState(() => _page = target);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _intro.dispose();
    _sheen.dispose();
    super.dispose();
  }

  void _trackTilt(Offset local, Size size) {
    if (!_ready) return;
    final dx = ((local.dx / size.width) - 0.5) * 2;
    final dy = ((local.dy / size.height) - 0.5) * 2;
    setState(() => _tilt = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0)));
  }

  Future<void> _open(int step, BuildContext cardContext) async {
    if (_opening || !_ready) return;
    _opening = true;
    try {
      if (_page != step && _pages.hasClients) {
        await _pages.animateToPage(
          step,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
      if (!mounted) return;
      if (lessonNeedsVerify(
        ref.read(authProvider),
        ref.read(verifyHoldProvider),
        ref.read(devUnlockProvider),
        step,
      )) {
        HapticFeedback.selectionClick();
        await showVerifySheet(context);
        return;
      }
      HapticFeedback.mediumImpact();
      await openLevelLessons(
        context,
        ref,
        step: step,
        bn: widget.bn,
        source: _cardRect(cardContext),
      );
    } finally {
      _opening = false;
    }
  }

  /// Axis-aligned bounds of the tapped card, including its tilt transform,
  /// so the shelf can grow from that spot over the header and the dock.
  Rect? _cardRect(BuildContext cardContext) {
    final box = cardContext.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    final far = box.localToGlobal(box.size.bottomRight(Offset.zero));
    final rect = Rect.fromPoints(origin, far);
    if (rect.width < 8 || rect.height < 8) return null;
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(pendingHomeRevealStepProvider, (prev, next) {
      if (next != null) _consumePendingReveal();
    });
    final ladderAsync = ref.watch(trainingLadderProvider);
    final ladder = ladderAsync.value ?? const <TrainingModuleItem>[];
    final achieved = widget.path.achieved;
    final orientationDone = isPathOrientationDone(
      ref.watch(allCompletedLessonsProvider),
    );
    final devOpen = ref.watch(devUnlockProvider);
    final auth = ref.watch(authProvider);
    final holds = ref.watch(verifyHoldProvider);

    // Run the open-scroll once the ladder data is actually available, so we
    // target the real present level (not the pre-load default of 1).
    if (_ready &&
        !_openScrollDone &&
        ladderAsync.hasValue &&
        ref.read(pendingHomeRevealStepProvider) == null) {
      _openScrollDone = true;
      _scrollToReadingLevel();
    }

    TrainingModuleItem? moduleFor(int step) {
      if (step <= 0) return null;
      for (final m in ladder) {
        if (m.moduleNumber == step) return m;
      }
      return null;
    }

    bool lockedFor(int step) {
      if (devOpen || step <= 0) return false;
      if (!orientationDone) return true;
      if (step <= achieved) return false;
      final item = moduleFor(step);
      return item?.isLocked ?? (step > achieved + 1);
    }

    return LayoutBuilder(
      builder: (context, box) {
        final area = Size(box.maxWidth, box.maxHeight);
        return Listener(
          onPointerDown: (e) => _trackTilt(e.localPosition, area),
          onPointerMove: (e) => _trackTilt(e.localPosition, area),
          onPointerUp: (_) => setState(() => _tilt = Offset.zero),
          onPointerCancel: (_) => setState(() => _tilt = Offset.zero),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: _tilt),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, tilt, _) {
              return AnimatedBuilder(
                animation: Listenable.merge([_pages, _intro, _sheen]),
                builder: (context, _) {
                  return PageView.builder(
                    controller: _pages,
                    physics: _ready
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: _last + 1,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final seal = lessonNeedsVerify(
                        auth,
                        holds,
                        devOpen,
                        index,
                      );
                      return _buildCard(
                        index,
                        tilt,
                        seal ? false : lockedFor(index),
                        seal,
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCard(int index, Offset tilt, bool locked, bool verifyTick) {
    final page = _pages.hasClients && _pages.position.haveDimensions
        ? (_pages.page ?? _page.toDouble())
        : _page.toDouble();
    final offset = (page - index).clamp(-1.5, 1.5);
    final focus = 1 - offset.abs().clamp(0.0, 1.0);
    final active = index == _page;

    // Intro: active card flips in from its back; neighbours fade in after.
    final t = _intro.value;
    final flipT = Curves.easeOutBack.transform((t / 0.8).clamp(0.0, 1.0));
    final flip = active ? (1 - flipT) * math.pi : 0.0;
    final neighbourIn = Curves.easeOut.transform(
      ((t - 0.55) / 0.45).clamp(0.0, 1.0),
    );
    final glow = Curves.easeOut.transform(((t - 0.5) / 0.5).clamp(0.0, 1.0));

    final cardTilt = active ? tilt : Offset.zero;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateY(offset * 0.42 + flip + cardTilt.dx * 0.12)
      ..rotateX(-cardTilt.dy * 0.1);
    final scale = 0.84 + 0.16 * focus;

    final showBack = flip > math.pi / 2;
    final sweep = _ready && active ? _sheen.value / 0.32 : -1.0;

    Widget face = showBack
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: HeroCardBack(step: index),
          )
        : HeroCard(
            step: index,
            title: heroTitle(index, widget.bn),
            locked: locked,
            verifyTick: verifyTick,
            tilt: cardTilt,
            sheen: sweep,
            glow: active ? glow * (0.75 + 0.25 * focus) : 0.35 * focus,
            enableHero: active && _ready,
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 20),
        child: Opacity(
          opacity: active ? 1 : (0.35 + 0.65 * focus) * neighbourIn,
          child: Transform(
            alignment: Alignment.center,
            transform: matrix..scaleByDouble(scale, scale, 1, 1),
            child: Builder(
              builder: (cardContext) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _open(index, cardContext),
                child: face,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
