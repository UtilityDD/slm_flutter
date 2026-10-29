import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../admin/dev_unlock.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_sheet.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'hero_card.dart';
import 'lesson_progress_store.dart';
import 'level_lessons_page.dart';
import 'level_zero_page.dart';
import 'lineman_progress.dart';

Future<void> playLessonCue(bool open) async {
  final player = AudioPlayer();
  try {
    await player.setReleaseMode(ReleaseMode.release);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setVolume(0.85);
    await player.play(
      AssetSource(open ? 'sounds/quiz_right.wav' : 'sounds/quiz_wrong.wav'),
    );
    player.onPlayerComplete.first.then((_) => player.dispose()).ignore();
  } catch (_) {
    await player.dispose();
  }
}

void showModernLockMessage(
  BuildContext context, {
  required bool bn,
  required String message,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      backgroundColor: const Color(0xFF1C1917),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF292524),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: banglaFont,
                fontSize: 14.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFAFAF9),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Rect _fitCard(Rect bounds, double aspect) {
  if (bounds.isEmpty) return bounds;
  final boundsAspect = bounds.width / bounds.height;
  if (boundsAspect > aspect) {
    final width = bounds.height * aspect;
    return Rect.fromCenter(
      center: bounds.center,
      width: width,
      height: bounds.height,
    );
  }
  final height = bounds.width / aspect;
  return Rect.fromCenter(
    center: bounds.center,
    width: bounds.width,
    height: height,
  );
}

String _shelfCardTitle(int step, bool bn) {
  if (step <= 0) return bn ? 'শুরু' : 'Start';
  final chapter =
      linemanChapters[(step - 1).clamp(0, linemanChapters.length - 1)];
  return bn ? chapter.$1 : chapter.$2;
}

/// Opens Level 0 orientation, or a module's lesson shelf.
///
/// [source] is the tapped card's global rect. When set, the shelf grows from
/// that rect on the root navigator, over the home header and the dock.
Future<void> openLevelLessons(
  BuildContext context,
  WidgetRef ref, {
  required int step,
  required bool bn,
  Rect? source,
}) async {
  HapticFeedback.lightImpact();

  // Level 0 is the path map — never the same as Level 1 lessons.
  if (step <= 0) {
    await playLessonCue(true);
    if (!context.mounted) return;
    await _openShelf(
      context,
      page: LevelZeroPage(bn: bn),
      source: source,
      step: step,
      bn: bn,
    );
    return;
  }

  if (lessonNeedsVerifyNow(context, step)) {
    if (!context.mounted) return;
    await showVerifySheet(context);
    return;
  }

  final devOpen = ref.read(devUnlockProvider);
  final completed = ref.read(allCompletedLessonsProvider);
  if (!devOpen && !isPathOrientationDone(completed)) {
    await playLessonCue(false);
    if (!context.mounted) return;
    showModernLockMessage(
      context,
      bn: bn,
      message: bn
          ? 'আগে লেভেল 0 · পথের মানচিত্র শেষ করুন।'
          : 'Finish Level 0 · Path map first.',
    );
    return;
  }

  final module = step.clamp(1, 10);
  final lookStep = step.clamp(0, 10);

  List<TrainingModuleItem> modules;
  try {
    modules = await ref.read(trainingLadderProvider.future);
  } catch (_) {
    modules = const [];
  }

  TrainingModuleItem? item;
  for (final m in modules) {
    if (m.moduleNumber == module) {
      item = m;
      break;
    }
  }

  final locked = !devOpen && (item?.isLocked ?? (module > 1));
  if (locked) {
    await playLessonCue(false);
    if (!context.mounted) return;
    showModernLockMessage(
      context,
      bn: bn,
      message: bn
          ? 'আগের লেভেল শেষ হলে এটি খুলবে।'
          : 'This opens after you finish the previous level.',
    );
    return;
  }

  await playLessonCue(true);
  if (!context.mounted) return;

  final badge =
      item?.badgeName ??
      (module <= staticBadgeNames.length
          ? staticBadgeNames[module - 1]
          : 'লেভেল $module');
  final title =
      item?.title ??
      (module <= staticChapterTitles.length
          ? staticChapterTitles[module - 1]
          : 'অধ্যায় $module');
  await _openShelf(
    context,
    page: LevelLessonsPage(
      moduleNumber: module,
      step: lookStep,
      badgeName: badge,
      chapterTitle: title,
      bn: bn,
    ),
    source: source,
    step: lookStep,
    bn: bn,
  );
}

Future<void> _openShelf(
  BuildContext context, {
  required Widget page,
  required Rect? source,
  required int step,
  required bool bn,
}) {
  final from = source;
  final grow = from != null && from.width >= 8 && from.height >= 8;
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder(
      opaque: !grow,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: grow ? 720 : 340),
      reverseTransitionDuration: Duration(milliseconds: grow ? 480 : 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, __, child) {
        final origin = from;
        if (!grow || origin == null) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        }
        return _CardExpandTransition(
          animation: animation,
          source: origin,
          step: step,
          title: _shelfCardTitle(step, bn),
          child: child,
        );
      },
    ),
  );
}

double _span(double t, double start, double end, Curve curve) {
  final x = ((t - start) / (end - start)).clamp(0.0, 1.0);
  return curve.transform(x);
}

/// Lifts the tapped card off the deck, turns it face-on, and lets the shelf
/// rise behind it. The card is laid out once and moved with a transform, so
/// the flight does not reflow every frame or clip under the header and dock.
class _CardExpandTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect source;
  final int step;
  final String title;
  final Widget child;

  const _CardExpandTransition({
    required this.animation,
    required this.source,
    required this.step,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dest = Offset.zero & size;
    final pad = MediaQuery.paddingOf(context);
    final aspect = source.height == 0 ? 0.66 : source.width / source.height;
    final safe = Rect.fromLTRB(
      dest.left + 16,
      dest.top + pad.top + 12,
      dest.right - 16,
      dest.bottom - pad.bottom - 36,
    );
    final fitted = _fitCard(safe, aspect);
    final metal = cardMetalFor(step);
    final startScale = fitted.width == 0
        ? 1.0
        : (source.width / fitted.width).clamp(0.2, 1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final reverse = animation.status == AnimationStatus.reverse;
        final move = (reverse ? Curves.easeInCubic : Curves.easeOutCubic)
            .transform(t);
        final scaleT = reverse ? move : Curves.easeOutBack.transform(t);
        final scale = (startScale + (1 - startScale) * scaleT).toDouble();
        final dx = (source.center.dx - fitted.center.dx) * (1 - move);
        final dy = (source.center.dy - fitted.center.dy) * (1 - move);
        final side = ((source.center.dx - size.width / 2) / size.width).clamp(
          -0.5,
          0.5,
        );
        final pitch = (1 - move) * 0.22;
        final yaw = (1 - move) * side * 0.55;
        final scrim = _span(t, 0, 0.42, Curves.easeOut);
        final pageIn = _span(t, 0.5, 1, Curves.easeOutCubic);
        final cardOut = _span(t, 0.72, 1, Curves.easeIn);
        final sheen = _span(t, 0.08, 0.62, Curves.easeInOut);
        final glowAlign = Alignment(
          ((source.center.dx + (fitted.center.dx - source.center.dx) * move) /
                      size.width) *
                  2 -
              1,
          ((source.center.dy + (fitted.center.dy - source.center.dy) * move) /
                      size.height) *
                  2 -
              1,
        );

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..translateByDouble(dx, dy, 0, 1)
          ..rotateX(pitch)
          ..rotateY(yaw)
          ..scaleByDouble(scale, scale, 1, 1);

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: glowAlign,
                  radius: 1.15,
                  colors: [
                    metal.glow.withValues(alpha: 0.55 * scrim * (1 - pageIn)),
                    const Color(0xFF0B1A18)
                        .withValues(alpha: 0.62 * scrim * (1 - pageIn * 0.35)),
                    const Color(0xFFF4EDE0).withValues(alpha: scrim),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
            IgnorePointer(
              ignoring: pageIn < 0.98,
              child: Opacity(
                opacity: pageIn,
                child: Transform.translate(
                  offset: Offset(0, 22 * (1 - pageIn)),
                  child: child,
                ),
              ),
            ),
            if (cardOut < 0.98)
              Positioned(
                left: fitted.left,
                top: fitted.top,
                width: fitted.width,
                height: fitted.height,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: (1 - cardOut).clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                      transform: matrix,
                      child: RepaintBoundary(
                        child: HeroCard(
                          step: step,
                          title: title,
                          locked: false,
                          enableHero: false,
                          sheen: sheen,
                          glow: 0.65 + 0.7 * move,
                          launch: math.sin(move * math.pi) * 0.42,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
