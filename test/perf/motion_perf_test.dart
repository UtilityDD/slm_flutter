// Performance regression guards for the motion engine (lib/design/motion)
// and the always-on Home / ladder loops. Each test prints a `PERF` line so a
// before/after run can be compared; the expectations are the fixed numbers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/home/home_screen.dart';
import 'package:slm_flutter/features/home/lineman_figure.dart';

const _frame = Duration(milliseconds: 16);

/// Counts every State.initState of the probe, i.e. every (re)mount.
class _Probe extends StatefulWidget {
  static int mounts = 0;
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.mounts++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 120, height: 40);
}

Widget _app(Widget child, {bool reduce = false}) => ProviderScope(
      child: MaterialApp(
        theme: SlmTheme.night(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );

/// Pumps [total] in 16 ms frames. Returns how many of those frames were
/// requested by the app (hasScheduledFrame) and how many widgets rebuilt.
Future<({int frames, int rebuilds, int steps})> _sample(WidgetTester tester, Duration total) async {
  var rebuilds = 0;
  var frames = 0;
  final prev = debugOnRebuildDirtyWidget;
  debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
  final steps = total.inMilliseconds ~/ _frame.inMilliseconds;
  for (var i = 0; i < steps; i++) {
    if (tester.binding.hasScheduledFrame) frames++;
    await tester.pump(_frame);
  }
  debugOnRebuildDirtyWidget = prev;
  return (frames: frames, rebuilds: rebuilds, steps: steps);
}

void _report(String what, ({int frames, int rebuilds, int steps}) r) {
  debugPrint('PERF $what: frames requested ${r.frames}/${r.steps}, '
      'widget rebuilds ${r.rebuilds} (${(r.rebuilds / r.steps).toStringAsFixed(2)}/frame)');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _Probe.mounts = 0;
  });

  group('design-motion-01 shimmer keeps its subtree', () {
    testWidgets('SlmShimmer does not remount its child across loops', (tester) async {
      await tester.pumpWidget(_app(const SlmShimmer(child: _Probe())));
      _Probe.mounts = 0;
      await _sample(tester, const Duration(milliseconds: 3400 * 3));
      debugPrint('PERF shimmer remounts over 3 loops (10.2 s): ${_Probe.mounts}');
      expect(_Probe.mounts, 0);
    });

    testWidgets('gold button keeps taps that straddle a shimmer edge', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(SlmButton.gold(label: 'শুরু করা যাক', onPressed: () => taps++)));
      final at = tester.getCenter(find.byType(SlmButton));
      // Band edges sit at 0 % and 45 % of each 3.4 s loop (0 ms, 1530 ms, 3400 ms…).
      var elapsed = 0;
      Future<void> advanceTo(int ms) async {
        while (elapsed + 16 <= ms) {
          await tester.pump(_frame);
          elapsed += 16;
        }
      }

      // Each press goes down before a band edge and lifts after it.
      for (final (down, up) in [(1490, 1590), (3370, 3470), (4900, 5000)]) {
        await advanceTo(down);
        final g = await tester.startGesture(at);
        await advanceTo(up);
        await g.up();
        await advanceTo(up + 400);
      }
      debugPrint('PERF gold button taps kept: $taps/3');
      expect(taps, 3);
    });
  });

  group('design-motion-13 shimmer idles between sweeps', () {
    testWidgets('SlmShimmer frames per loop', (tester) async {
      await tester.pumpWidget(_app(const SlmShimmer(child: _Probe())));
      final r = await _sample(tester, const Duration(milliseconds: 3400 * 2));
      _report('SlmShimmer 2 loops', r);
      expect(r.frames, lessThan(r.steps * 0.5));
      expect(r.rebuilds, lessThan(r.steps * 0.5));
    });
  });

  group('design-motion-02 Home shield', () {
    testWidgets('AnimatedSafetyShield per-frame cost while looping', (tester) async {
      await tester.pumpWidget(_app(const AnimatedSafetyShield(size: 220, entrance: false)));
      await tester.pump(const Duration(seconds: 1));
      final r = await _sample(tester, const Duration(seconds: 2));
      _report('shield loop 2 s', r);
      // The emblem still animates every frame, but only a few widgets rebuild.
      expect(r.rebuilds / r.steps, lessThanOrEqualTo(4));
    });

    testWidgets('AnimatedSafetyShield requests no frames with remove-animations', (tester) async {
      await tester.pumpWidget(_app(const AnimatedSafetyShield(size: 220), reduce: true));
      await tester.pump(const Duration(seconds: 1));
      final r = await _sample(tester, const Duration(seconds: 2));
      _report('shield reduce-motion 2 s', r);
      expect(r.frames, 0);
    });

    testWidgets('idle Home requests no frames with remove-animations', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen(), reduce: true));
      await tester.pump(const Duration(seconds: 3));
      final r = await _sample(tester, const Duration(seconds: 3));
      _report('Home idle reduce-motion 3 s', r);
      expect(r.frames, 0);
    });
  });

  group('home-game-09 AI Line Man guide', () {
    testWidgets('idle guide cost per eye loop', (tester) async {
      await tester.pumpWidget(_app(const AiLinemanGuide(sprite: 72, bubbleWidth: 150)));
      await tester.pump(const Duration(seconds: 1));
      final r = await _sample(tester, const Duration(milliseconds: 4800 * 2));
      _report('guide idle 2 eye loops (9.6 s)', r);
      // Blink + glance are a handful of state changes, not 60 fps.
      expect(r.frames, lessThan(r.steps * 0.1));
      expect(r.rebuilds, lessThan(r.steps * 0.5));
    });

    testWidgets('guide requests no frames with remove-animations', (tester) async {
      await tester.pumpWidget(_app(const AiLinemanGuide(sprite: 72), reduce: true));
      await tester.pump(const Duration(seconds: 1));
      final r = await _sample(tester, const Duration(seconds: 5));
      _report('guide reduce-motion 5 s', r);
      expect(r.frames, 0);
    });

    testWidgets('guide faces decode at display size', (tester) async {
      await tester.pumpWidget(_app(const AiLinemanGuide(sprite: 72)));
      await tester.pump(const Duration(milliseconds: 400));
      final dpr = tester.view.devicePixelRatio;
      final images = tester.widgetList<Image>(find.descendant(
        of: find.byType(AiLinemanGuide),
        matching: find.byType(Image),
      ));
      final heights = [
        for (final i in images) i.image is ResizeImage ? (i.image as ResizeImage).height : null,
      ];
      debugPrint('PERF guide face decode heights (sprite 72, dpr $dpr): $heights');
      expect(heights, isNotEmpty);
      expect(heights, everyElement((72 * dpr).round()));
    });
  });

  group('design-motion-05 one reduced-motion policy', () {
    testWidgets('LinemanFigure breathing stops with remove-animations', (tester) async {
      await tester.pumpWidget(_app(const SizedBox(width: 150, child: LinemanFigure(step: 2, enableHero: false)),
          reduce: true));
      await tester.pump(const Duration(seconds: 1));
      final r = await _sample(tester, const Duration(seconds: 3));
      _report('lineman figure reduce-motion 3 s', r);
      expect(r.frames, 0);
    });

    testWidgets('LinemanFigure breathing rebuilds only the scale', (tester) async {
      await tester.pumpWidget(_app(const SizedBox(width: 150, child: LinemanFigure(step: 2, enableHero: false))));
      await tester.pump(const Duration(seconds: 1));
      final r = await _sample(tester, const Duration(seconds: 2));
      _report('lineman figure breathing 2 s', r);
      expect(r.rebuilds / r.steps, lessThanOrEqualTo(2));
    });
  });

  group('design-motion-14 tokens', () {
    testWidgets('context.slm reuses the type scale', (tester) async {
      late SlmType a;
      late SlmType b;
      await tester.pumpWidget(_app(Builder(builder: (context) {
        a = context.slm.type;
        b = context.slm.type;
        return const SizedBox();
      })));
      debugPrint('PERF context.slm.type reused across calls: ${identical(a, b)}');
      expect(identical(a, b), isTrue);
    });
  });
}
