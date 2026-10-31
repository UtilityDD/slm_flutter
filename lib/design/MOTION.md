# SmartLineman motion engine

Everything is exported from `package:slm_flutter/design/slm_design.dart`.
No packages were added; it is all built on Flutter's own animation classes.

## Shield assets

| Path | What it is |
|---|---|
| `assets/brand/source/shield_reference.jpg` | Original art, unchanged. Not bundled in the app. |
| `assets/brand/shield_body.webp` | Shield only, transparent background, baked-in ring removed (295 × 381, 26 KB). |
| `assets/brand/shield_rim.webp` | White + alpha mask of the gold border, same crop. Drives the travelling rim light. |
| `assets/brand/shield_glass.webp` | White + alpha mask of the green glass, same crop. Drives the emerald tint and glass sheen. |

The three layers share one crop, so they stack pixel for pixel. The ring is
painted in code (`_RingPainter`) on the ellipse fitted to the ring in the
original art: rear half under the shield, front half over it. Its front arc
covers the thin seam left where the old ring was removed, so keep the ring
geometry constants in `slm_safety_shield.dart` unchanged unless the layers are
regenerated.

## Global switches

Wrap a subtree in `SlmMotionScope(settings: SlmMotionSettings(), child: …)` to
pause loops, switch them off, or replay entrances (`replayEntrances()`).
Without a scope everything plays. The phone's "remove animations" setting
always turns loops and entrances off.

## Widgets

- `AnimatedSafetyShield(size: 220, animate: true)`: signature emblem. Options:
  `entrance`, `controller` (`AnimatedSafetyShieldController.replayEntrance()`),
  `revolution`, `intensity`, `heroTag`.
- `SlmButton` (and `.gold`, `.secondary`, `.ghost`): press depth, spring
  release, one light sweep per tap, `loading`, disabled when `onPressed` is null.
- `SlmTactile(builder: (context, press, child) …)`: press physics for custom
  tappables; `press` runs 0 → 1 and springs slightly below 0 on release.
- `SlmMotionCard(index: i, onTap: …)`: staggered entrance, lift and gold edge
  light on press, optional `float` (one per screen).
- `SlmContentSwitcher`: cross-fade + rise + resize between keyed children.
- `SlmXpBar(value:)`: animates from the previous value; fresh progress glows
  gold; reaching 1.0 flashes and calls `onFilled`.
- `SlmProgressRing`, `SlmStepProgress`, `SlmAchievementCounter`,
  `SlmLevelMeter`, `SlmCountUp`: progress displays that animate to new data.
- `showSlmXpToast(context, amount: 20, anchor: key.currentContext)`.
- `showSlmBadgeUnlock(context, icon:, title:, caption:)`.
- `showSlmLevelUp(context, fromLevel:, toLevel:, heading:, title:, reward:)`.
- `SlmSparkBurst(trigger: value)`: small burst whenever `trigger` changes.
- `SlmReveal`, `SlmStagger`, `SlmStaggeredText`: entrances.
- `SlmShimmer`, `SlmSweepMask`, `SlmPulse`, `SlmFloat`, `SlmRays`: lighting loops.
- `SlmPageRoute(builder:, style: SlmTransition.fadeThrough)`: route with the
  shared motion; `SlmPageTransitionsBuilder` does the same through
  `ThemeData.pageTransitionsTheme`. `SlmStepSwitcher` for onboarding steps.

Rewards are display only. Call them after the existing scoring code has
saved the result; they never change points, levels or the leaderboard.
