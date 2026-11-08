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

## App logo, launch screen and intro

| Path | What it is |
|---|---|
| `assets/brand/source/app_icon_512.png` | The app logo (gear and bolt on navy #0E162B). Not bundled. `python -I tool/brand_assets.py .` makes every icon and launch-screen size from it: Android launcher (legacy, adaptive, themed), Android launch screen (pre-12 and 12+), iOS AppIcon and LaunchImage, and `assets/brand/splash_logo.png`. |
| `assets/brand/intro.mp4` | The brand intro (5.7 s, 464 × 832, H.264 Main 30 fps + AAC 64 kb/s, faststart, 330 KB; the source clip trimmed of its black lead-in and cut at the white flash). |

`lib/features/startup/intro_video.dart` (`IntroGate`) plays it once per cold start over Home: the native navy+logo screen hands over to the same navy and logo, the video fades in, a skip chip (এড়িয়ে যান) appears after 1.2 s, and the layer fades into the app at the end. Reduced motion skips it; a video that fails or takes over 2.5 s to load never holds the app. Widget tests run without it (`FLUTTER_TEST`).

While it plays, `warmUpDuringIntro` (`lib/core/startup/startup_warmup.dart`) loads what the first taps would wait for: the ladder's content catalog, Module 1's lessons (network, kept on disk), the device TTS engine, players for the most used sound cues, and the ladder map's coins at their decode size. Local steps first with a frame's pause between them (the video keeps its frames); every step has a time limit, swallows errors, never holds the app, keeps running if the intro is skipped, and is timed in `StartupTrace.background` as `warm:<name>`.

The three layers share one crop, so they stack pixel for pixel. The ring is
painted in code (`_RingPainter`) on the ellipse fitted to the ring in the
original art: rear half under the shield, front half over it. Its front arc
covers the thin seam left where the old ring was removed, so keep the ring
geometry constants in `slm_safety_shield.dart` unchanged unless the layers are
regenerated.

## Reduced-motion policy (one for the whole app)

All in `motion/slm_motion_scope.dart`:

- `slmReduceMotion(context)`: true when the phone's "remove animations" is on. Use it for one-shot entrances and transitions. Do not read `MediaQuery.disableAnimationsOf` in feature code.
- `slmLoopsOn(context)`: may looping decoration run here.
- `slmSyncLoop(context, controller, enabled:, reverse:, restAt:)`: starts or stops a `repeat()` loop to match. Call it from `didChangeDependencies`, and from `didUpdateWidget` when `enabled` depends on widget fields. Never call `repeat()` straight in `initState`. A stopped loop schedules no frames; `restAt` snaps it to a rest pose.

`SlmMotionScope` / `SlmMotionSettings` (pause, loops off, `replayEntrances()`) exist, but no screen installs one. Without a scope, loops play unless "remove animations" is on.

Not yet on the policy (fix when you touch them): about 20 `.repeat(` calls in `lib/features` (duty slip, dress-up, ladder, path fear, celebration, quiz turn card) and direct `MediaQuery.disableAnimationsOf` reads in `duty_slip_page.dart`, `path_fear_page.dart` and `learn_runner.dart`. Duty slip also has `DsMotionGate` (`duty_slip_page.dart`), which drops its own effects to a `lite` tier when frames run slow.

## Keeping motion cheap

- Never switch a child between `child` and `Wrapper(child)` as an animation
  runs: the subtree remounts and taps in progress are lost. Use
  `SlmLiveShaderMask` (shader or null per paint, driven by `repaint:`), or keep
  the wrapper and pass an identity value.
- Drive paint-only changes with `CustomPaint(painter: P(repaint: controller))`
  or `SlmLiveShaderMask(repaint:)` and fades with `FadeTransition` or
  `Image(opacity:)`, so loops repaint and do not rebuild.
- Idle gaps belong on a `Timer`, not on a ticking controller (see `SlmShimmer`
  and the AI Line Man eyes).
- `test/perf/motion_perf_test.dart` guards remounts, taps, rebuilds per frame
  and frames requested with remove-animations on.

## Widgets

Used by app screens today:

- `AnimatedSafetyShield(size:, animate:)`: the মৃত্যুহীন পথ emblem. Options: `entrance`, `controller` (`replayEntrance()`), `revolution`, `intensity`, `heroTag`.
- `SlmButton` (`.gold`, `.secondary`, `.ghost`): press depth, spring release, one light sweep per tap, `loading`, disabled when `onPressed` is null. **`.gold` defaults to `shine: true`, a continuous `SlmShimmer`.** Pass `shine: false` where a loop is not wanted.
- `SlmPressable` and `SlmTactile(builder: (context, press, child) …)`: press feedback for custom tappables.
- `SlmReveal` (with `index`): staggered entrance.
- `SlmShimmer`: one slow highlight; the idle gap runs on a `Timer`.
- `SlmSweepMask` / `SlmLiveShaderMask`: light sweep without swapping the widget type (see above).
- `SlmPulse`, `SlmSparkBurst(trigger:)`, `SlmCountUp`, `showSlmXpToast`.
- `SlmPageRoute(builder:, style: SlmTransition.…)`: route with the shared motion.

Built but with no app caller yet (check before you add a new one): `SlmMotionCard`, `SlmContentSwitcher`, `SlmXpBar`, `SlmProgressRing`, `SlmStepProgress`, `SlmAchievementCounter`, `SlmLevelMeter`, `SlmStagger`, `SlmStaggeredText`, `SlmStepSwitcher`, `SlmFloat`, `SlmRays`, `showSlmBadgeUnlock`, `showSlmLevelUp`, `SlmMotionScope`. `SlmPageTransitionsBuilder` is not wired into any `ThemeData.pageTransitionsTheme`.

Rewards are display only. Call them after the existing scoring code has
saved the result; they never change points, levels or the leaderboard.
