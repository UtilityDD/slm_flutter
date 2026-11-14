// Performance guards for the AI Line Man guide (ai_lineman_guide.dart), which
// every level, the ladder and every learn board mounts. Each test prints a
// `PERF guide …` line so a before/after run can be compared.
//
//  * frames one guide line costs, muted (no voice) and voiced,
//  * widget rebuilds per second while the guide idles (eye blinks),
//  * whether his talking frames repaint the scene behind him,
//  * the speech bubble: it fades after the voice ends (or after a reading
//    time when muted), a tap or a new line brings it back, keepBubble holds it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';

const _frame = Duration(milliseconds: 16);
const _line = 'খুঁটিতে ওঠার আগে আর্থিং দেখে নিন।';

/// Paints behind the guide in the same layer, like a level's scene: counts
/// scene repaints.
class _ScenePainter extends CustomPainter {
  static int paints = 0;
  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A1424));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => false;
}

Widget _app(ProviderContainer c, {bool keepBubble = false, bool reduce = false, VoidCallback? onTap}) =>
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: SlmTheme.night(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _ScenePainter())),
                  Positioned(
                    right: 0,
                    bottom: 40,
                    child: AiLinemanGuide(
                      sprite: 116,
                      bubbleWidth: 232,
                      large: true,
                      centered: false,
                      keepBubble: keepBubble,
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

/// Pumps 16 ms frames until no frame is scheduled (or [max]); returns frames.
Future<int> _framesUntilQuiet(WidgetTester tester, {Duration max = const Duration(seconds: 10)}) async {
  var frames = 0;
  final steps = max.inMilliseconds ~/ _frame.inMilliseconds;
  for (var i = 0; i < steps; i++) {
    if (!tester.binding.hasScheduledFrame) break;
    frames++;
    await tester.pump(_frame);
  }
  return frames;
}

/// Pumps [total] in 16 ms frames; counts requested frames and rebuilds.
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

Finder get _bubble => find.text(_line);

/// Lets [ms] pass in 50 ms frames (a fade needs frames to run).
Future<void> _wait(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await _framesUntilQuiet(tester);
}

void main() {
  late ProviderContainer c;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MascotTalk.reset();
    c = ProviderContainer();
  });
  tearDown(() {
    MascotTalk.reset();
    c.dispose();
  });

  GuideDirector director() => c.read(guideDirectorProvider.notifier);

  testWidgets('a muted line costs one frame (no 6 s breath lap)', (tester) async {
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    director().say(mood: GuideMood.talk, line: _line);
    final frames = await _framesUntilQuiet(tester);
    // A mood that changes his face adds only the 220 ms face cross-fade.
    director().say(mood: GuideMood.glad, line: 'সাবাশ!');
    final newFace = await _framesUntilQuiet(tester);
    debugPrint('PERF guide muted line: $frames frames (same face), $newFace frames (new face)');
    expect(frames, 1);
    expect(newFace, lessThan(20));
    await _wait(tester, 5000); // the praise line's own soft-clear
  });

  testWidgets('a voiced line: the rig runs while he speaks, then eases back', (tester) async {
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    director().say(mood: GuideMood.talk, line: _line);
    MascotTalk.begin();
    await tester.pump();
    final scene0 = _ScenePainter.paints;
    final talking = await _sample(tester, const Duration(seconds: 2));
    final scene = _ScenePainter.paints - scene0;
    MascotTalk.end();
    final tail = await _framesUntilQuiet(tester);
    debugPrint('PERF guide voiced line: talking 2 s ${talking.frames}/${talking.steps} frames, '
        '${talking.rebuilds} rebuilds, scene repaints $scene; tail after voice $tail frames');
    expect(tail, lessThan(45), reason: 'about 0.5 s ease-back, not the rest of a 6 s lap');
    expect(scene, 0, reason: 'his talking frames repaint his own layer, not the scene');
  });

  testWidgets('idle guide: blinks rebuild nothing and draw no frames', (tester) async {
    await tester.pumpWidget(_app(c));
    director().say(mood: GuideMood.talk, line: _line);
    await _settle(tester);
    await _wait(tester, 5000); // the line read and its bubble faded
    await _framesUntilQuiet(tester);
    // Two eye laps: blinks, a double blink, glances.
    final scene0 = _ScenePainter.paints;
    final r = await _sample(tester, const Duration(seconds: 12));
    final scene = _ScenePainter.paints - scene0;
    final perSec = r.rebuilds / 12;
    debugPrint('PERF guide idle 12 s: frames ${r.frames}/${r.steps}, rebuilds ${r.rebuilds} '
        '(${perSec.toStringAsFixed(2)}/s), scene repaints $scene');
    expect(r.frames, 0);
    expect(perSec, lessThan(1));
    expect(scene, 0);
  });

  testWidgets('idle guide still blinks and glances', (tester) async {
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    final eyes = find.descendant(of: find.byType(AiLinemanGuide), matching: find.byType(FadeTransition));
    var shown = 0;
    for (var i = 0; i < 12000 ~/ 30; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      if (tester.widgetList<FadeTransition>(eyes).any((f) => f.opacity.value > 0.9)) shown++;
    }
    debugPrint('PERF guide eye face shown in $shown of 400 samples (12 s)');
    expect(shown, greaterThan(0));
  });

  testWidgets('the guide has his own repaint boundary', (tester) async {
    await tester.pumpWidget(_app(c));
    await _settle(tester);
    RenderObject? b = tester.renderObject(find.byType(AiLinemanGuide));
    while (b != null && !b.isRepaintBoundary) {
      b = b.parent;
    }
    final size = (b! as RenderBox).size;
    debugPrint('PERF guide nearest repaint boundary: ${b.runtimeType} $size');
    expect(size.width * size.height, lessThan(300 * 400));
  });

  group('speech bubble', () {
    testWidgets('fades about 1.5 s after the voice ends', (tester) async {
      await tester.pumpWidget(_app(c));
      await _settle(tester);
      director().say(mood: GuideMood.talk, line: _line);
      MascotTalk.begin();
      await _wait(tester, 100);
      expect(_bubble, findsOneWidget);
      await _wait(tester, 3000);
      expect(_bubble, findsOneWidget, reason: 'stays while he speaks');
      MascotTalk.end();
      await _wait(tester, 1000);
      expect(_bubble, findsOneWidget, reason: 'still readable just after the voice');
      await _wait(tester, 1000);
      await _wait(tester, 400);
      expect(_bubble, findsNothing, reason: 'gone ~1.5 s after the voice');
    });

    testWidgets('muted: fades after a reading time; a tap brings it back', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(c, onTap: () => taps++));
      await _settle(tester);
      director().say(mood: GuideMood.talk, line: _line);
      await _wait(tester, 100);
      expect(_bubble, findsOneWidget);
      // 0.9 s + 70 ms × chars, clamped 2.5–7 s.
      final read = (900 + _line.length * 70).clamp(2500, 7000);
      await _wait(tester, read - 400);
      expect(_bubble, findsOneWidget, reason: 'held for its reading time');
      await _wait(tester, 800);
      await _wait(tester, 400);
      expect(_bubble, findsNothing);
      await tester.tap(find.byType(AiLinemanGuide), warnIfMissed: false);
      await _wait(tester, 100);
      expect(taps, 1);
      expect(_bubble, findsOneWidget, reason: 'a tap shows the line again');
      await _wait(tester, read + 800);
      expect(_bubble, findsNothing);
      // A new line always shows.
      director().say(mood: GuideMood.warn, line: 'আগে গ্লাভস পরুন।');
      await _wait(tester, 100);
      expect(find.text('আগে গ্লাভস পরুন।'), findsOneWidget);
      await _wait(tester, 8000);
    });

    testWidgets('a tap that re-says the task shows it and speaks', (tester) async {
      late GuideDirector d;
      await tester.pumpWidget(_app(c, onTap: () {
        d.say(mood: GuideMood.talk, line: _line);
        MascotTalk.begin();
      }));
      d = director();
      await _settle(tester);
      d.say(mood: GuideMood.talk, line: _line);
      await _wait(tester, 8000);
      expect(_bubble, findsNothing);
      await tester.tap(find.byType(AiLinemanGuide), warnIfMissed: false);
      await _wait(tester, 100);
      expect(_bubble, findsOneWidget);
      expect(MascotTalk.active.value, isTrue);
      await _wait(tester, 9000);
      expect(_bubble, findsOneWidget, reason: 'held while the voice runs');
      MascotTalk.end();
      await _wait(tester, 2000);
      await _wait(tester, 400);
      expect(_bubble, findsNothing);
    });

    testWidgets('keepBubble holds the line (learn board questions)', (tester) async {
      await tester.pumpWidget(_app(c, keepBubble: true));
      await _settle(tester);
      director().say(mood: GuideMood.talk, line: _line);
      await _wait(tester, 12000);
      expect(_bubble, findsOneWidget);
    });
  });
}
