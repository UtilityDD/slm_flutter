import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../guide/ai_lineman_guide.dart';
import 'gesture_hint.dart';
import 'level_shell.dart';
import 'reason_table.dart';

// The full-screen level frame every Do level uses (GAME_LEVEL_PLAYBOOK.md §1–2):
// the scene runs edge to edge — under the status bar and the header, to the
// bottom — the header (ধাপ · ◆ · 💀) floats on it without a bar, a soft shade
// keeps the chips readable, and pages put their cards over it.
//
// The scene is designed 360 wide; its height follows the screen (a tall phone
// gets more sky, never a stretched picture). Layers get [SceneMetrics].
//
// Input shield: while a right move's ◆ waits on the table and the praise
// plays ([ReasonTable.tableHolding], found above this frame by itself, or
// [FullSceneFrame.inputBlocked]) the scene and the overlays take no touch;
// the header (close, mute) stays live.
//
// Gesture hint: pass [FullSceneFrame.hint] + [FullSceneFrame.hintWaiting] and
// the frame shows the hand after idle / confusion (gesture_hint.dart).

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
    this.inputBlocked,
    this.hint,
    this.hintWaiting = false,
    this.hintKey,
    this.hintController,
    this.hintAutoMiss = false,
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

  /// Block every touch on the scene and overlays (not the header). Null =
  /// automatic: blocked during a [ReasonTable]'s praise window.
  final bool? inputBlocked;

  /// The gesture hint for now (how to interact, never the answer); anchors in
  /// global, local or scene ([HintSpace.scene], design pixels) space.
  final HintSpec? Function()? hint;

  /// The level waits for the player's input now (no intro, card, deck,
  /// voice-locked beat or animation). The hand shows only while true.
  final bool hintWaiting;

  /// A new value (e.g. the round) resets the count of hints shown.
  final Object? hintKey;

  /// Lets the level report taps on nothing ([IdleHintController.missTap]).
  final IdleHintController? hintController;

  /// Count taps that hit no small widget as misses (see [IdleHint.autoMiss]).
  final bool hintAutoMiss;

  /// Header band (status bar + the floating HUD) that stays live under the shield.
  static const double headerBand = 62;

  /// Whether input is blocked now (explicit, or a [ReasonTable] above is in its
  /// praise window).
  bool _blocked(BuildContext context) => inputBlocked ?? (context.findAncestorStateOfType<ReasonTable>()?.tableHolding ?? false);

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked(context);
    final pad = MediaQuery.paddingOf(context);
    final h = hint;
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.max(1.0, box.maxWidth);
        final sh = (360 * box.maxHeight / w).clamp(560.0, 900.0);
        final scale = math.max(box.maxWidth / 360, box.maxHeight / sh);
        final dx = (box.maxWidth - 360 * scale) / 2;
        final dy = (box.maxHeight - sh * scale) / 2;
        return IdleHint(
          waiting: hintWaiting && h != null && !blocked,
          waitKey: hintKey,
          controller: hintController,
          autoMiss: hintAutoMiss,
          sceneToLocal: (p) => Offset(dx + p.dx * scale, dy + p.dy * scale),
          spec: (_) => h?.call(),
          child: _frame(context, blocked, pad),
        );
      },
    );
  }

  Widget _frame(BuildContext context, bool blocked, EdgeInsets pad) {
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
        // The praise-window shield: over the scene and the overlays, never
        // over the header band.
        Positioned.fill(
          key: const ValueKey('scene-input-shield'),
          child: _SceneShield(active: blocked, passTop: pad.top + headerBand),
        ),
      ],
    );
  }
}

/// Swallows every touch on the scene and the overlays while [active]. Inside a
/// [FullSceneFrame] the header band (status bar + [FullSceneFrame.headerBand]:
/// close, mute) stays live; outside one the whole box absorbs. [child] is
/// decoration only and never takes a touch. Used by the death freeze
/// ([FreezeFrame]) so the heartbeat can still be muted and the level closed.
class HeaderSafeShield extends StatelessWidget {
  const HeaderSafeShield({super.key, required this.active, this.child});
  final bool active;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final inFrame = context.findAncestorWidgetOfExactType<FullSceneFrame>() != null;
    final passTop = inFrame ? MediaQuery.paddingOf(context).top + FullSceneFrame.headerBand : double.negativeInfinity;
    return _SceneShield(active: active, passTop: passTop, global: true, child: child);
  }
}

/// Swallows every touch below [passTop] while [active] (a full-screen
/// AbsorbPointer with a hole for the header). [global]: [passTop] is a screen
/// y (the box may not start at the top of the screen); else a local y. The
/// child never takes touches.
class _SceneShield extends SingleChildRenderObjectWidget {
  const _SceneShield({required this.active, required this.passTop, this.global = false, super.child});
  final bool active;
  final double passTop;
  final bool global;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSceneShield(active, passTop, global);

  @override
  void updateRenderObject(BuildContext context, _RenderSceneShield renderObject) {
    renderObject
      ..active = active
      ..passTop = passTop
      ..global = global;
  }
}

class _RenderSceneShield extends RenderProxyBox {
  _RenderSceneShield(this.active, this.passTop, this.global);
  bool active;
  double passTop;
  bool global;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!active || !size.contains(position)) return false;
    final y = global ? localToGlobal(position).dy : position.dy;
    if (y < passTop) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
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
