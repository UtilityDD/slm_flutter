import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../guide/ai_lineman_guide.dart';
import 'level_shell.dart';

// The full-screen level frame every Do level uses (GAME_LEVEL_PLAYBOOK.md §1–2):
// the scene runs edge to edge — under the status bar and the header, to the
// bottom — the header (ধাপ · ◆ · 💀) floats on it without a bar, a soft shade
// keeps the chips readable, and pages put their cards over it.
//
// The scene is designed 360 wide; its height follows the screen (a tall phone
// gets more sky, never a stretched picture). Layers get [SceneMetrics].

@immutable
class SceneMetrics {
  const SceneMetrics({required this.height, required this.lift, required this.inset});

  /// The design height (360 wide).
  final double height;

  /// How much lower the ground row sits than in a 420-high design.
  final double lift;

  /// The bottom system inset, in design pixels (keep controls above it).
  final double inset;
}

class FullSceneFrame extends StatelessWidget {
  const FullSceneFrame({
    super.key,
    required this.ctx,
    required this.titleBn,
    required this.scoreKey,
    required this.levelScore,
    required this.muted,
    required this.onClose,
    required this.onToggleMute,
    required this.layers,
    this.progress,
    this.animation,
    this.overlays = const [],
    this.liftBaseline = 532,
  });

  final LevelContext ctx;
  final String titleBn;
  final GlobalKey scoreKey;
  final int levelScore;
  final bool muted;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;

  /// The scene's layers, in design pixels (360 x [SceneMetrics.height]).
  /// Key every layer that comes and goes (unkeyed siblings are matched by
  /// position and rebuild from scratch when one disappears).
  final List<Widget> Function(BuildContext context, SceneMetrics m) layers;

  /// Under the header (e.g. round dots).
  final Widget? progress;

  /// Rebuilds the layers while it runs (e.g. a camera pan).
  final Listenable? animation;

  /// Page-level cards over everything (mistake card, intro, result …).
  final List<Widget> overlays;

  /// The ground row moves down by `height − liftBaseline`.
  final double liftBaseline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = math.max(1.0, box.maxWidth);
              final h = (360 * box.maxHeight / w).clamp(560.0, 900.0);
              final m = SceneMetrics(height: h, lift: h - liftBaseline, inset: MediaQuery.paddingOf(context).bottom * 360 / w);
              Widget stack(BuildContext c) => Stack(children: layers(c, m));
              final anim = animation;
              return ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 360,
                    height: h,
                    child: anim == null ? Builder(builder: stack) : AnimatedBuilder(animation: anim, builder: (c, _) => stack(c)),
                  ),
                ),
              );
            },
          ),
        ),
        // A soft shade under the status bar and the header chips.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.paddingOf(context).top + 96,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB3091329), Color(0x00091329)],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              LevelShellBar(
                bare: true,
                context_: ctx,
                titleBn: titleBn,
                scoreKey: scoreKey,
                levelScore: levelScore,
                muted: muted,
                onClose: onClose,
                onToggleMute: onToggleMute,
              ),
              ?progress,
            ],
          ),
        ),
        ...overlays,
      ],
    );
  }
}

/// The guide — the app's own mascot — in a bottom corner of the scene, with
/// his bubble; tap him for the task again. [bottom] in design pixels. Only
/// the mascot takes touches: taps on his bubble go through to the scene (the
/// places, the switch … under it).
Widget cornerGuide({required VoidCallback onTap, required double bottom, bool onLeft = false}) => Positioned(
      key: const ValueKey('hud-guide'),
      left: onLeft ? 0 : null,
      right: onLeft ? null : 0,
      bottom: bottom,
      child: _HitOnlyCorner(
        side: _guideSprite,
        child: AiLinemanGuide(sprite: _guideSprite, bubbleWidth: 232, showBubble: true, large: true, centered: false, onTap: onTap),
      ),
    );

const double _guideSprite = 116;

/// Takes touches only in its bottom-right [side] × [side] square (where the
/// mascot stands; his bubble above lets them through).
class _HitOnlyCorner extends SingleChildRenderObjectWidget {
  const _HitOnlyCorner({required this.side, required super.child});
  final double side;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitOnlyCorner(side);

  @override
  void updateRenderObject(BuildContext context, _RenderHitOnlyCorner renderObject) => renderObject.side = side;
}

class _RenderHitOnlyCorner extends RenderProxyBox {
  _RenderHitOnlyCorner(this.side);
  double side;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final corner = Rect.fromLTWH(size.width - side, size.height - side, side, side);
    if (!corner.contains(position)) return false;
    return super.hitTest(result, position: position);
  }
}
