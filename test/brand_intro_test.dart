// The brand intro over the app (drawn in code): it plays once with its sound,
// then fades into the app; the skip chip, reduced motion and a missing sound
// all end in the app; the drawing paints at every moment of its timeline.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/startup/brand_intro.dart';

class _Sound implements IntroSound {
  var played = 0, stopped = 0;
  @override
  Future<void> play() async => played++;
  @override
  Future<void> stop() async => stopped++;
}

Widget _app(IntroSound sound, {Future<void> Function(BuildContext)? warmUp}) => MaterialApp(
      home: IntroGate(sound: sound, warmUp: warmUp, child: const Scaffold(body: Text('app'))),
    );

void main() {
  testWidgets('plays once with its sound, then fades into the app', (t) async {
    final s = _Sound();
    await t.pumpWidget(_app(s));
    expect(find.byType(IntroOverlay), findsOneWidget);
    await t.pump();
    expect(s.played, 1);
    await t.pump(const Duration(seconds: 3));
    expect(find.byType(IntroOverlay), findsOneWidget, reason: 'still playing at 3 s');
    await t.pump(const Duration(milliseconds: 2600));
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing);
    expect(find.text('app'), findsOneWidget);
    expect(s.stopped, 0, reason: 'the last hit plays on as the app appears');
  });

  testWidgets('the skip chip comes after a moment, stops the sound and leaves', (t) async {
    final s = _Sound();
    await t.pumpWidget(_app(s));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text(IntroGate.skipBn), findsNothing);
    await t.pump(IntroGate.skipAfter);
    expect(find.text(IntroGate.skipBn), findsOneWidget);
    await t.tap(find.text(IntroGate.skipBn));
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing);
    expect(s.stopped, 1);
  });

  testWidgets('reduced motion: the still lockup briefly, no sound', (t) async {
    final s = _Sound();
    await t.pumpWidget(MediaQuery(data: const MediaQueryData(disableAnimations: true), child: _app(s)));
    await t.pump();
    expect(find.byType(IntroOverlay), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing);
    expect(s.played, 0);
  });

  testWidgets('the warm-up starts with the intro and runs on after it', (t) async {
    final warm = Completer<void>();
    var started = 0;
    await t.pumpWidget(_app(_Sound(), warmUp: (_) {
      started++;
      return warm.future;
    }));
    await t.pump();
    expect(started, 1);
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(find.text('app'), findsOneWidget);
    expect(started, 1);
    warm.complete();
  });

  testWidgets('disabled: the app straight away', (t) async {
    await t.pumpWidget(const MaterialApp(home: IntroGate(enabled: false, child: Text('app'))));
    expect(find.byType(IntroOverlay), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  test('the drawing paints at every moment, on a short and a tall phone', () {
    for (final size in const [Size(360, 640), Size(392, 850), Size(800, 1280)]) {
      for (var ms = 0; ms <= 6000; ms += 50) {
        final rec = ui.PictureRecorder();
        BrandIntroPainter(
          t: ms / 1000,
          title: const TextStyle(fontFamily: 'PoppinsBrand', fontWeight: FontWeight.w800),
          subtitle: const TextStyle(fontSize: 17),
        ).paint(Canvas(rec), size);
        rec.endRecording().dispose();
      }
    }
  });

  test('the logo geometry: 12 teeth, a closed gear, the bolt crosses the ring', () {
    expect(BrandLogo.pieces.length, 12);
    final b = BrandLogo.gearFill.getBounds();
    expect(b.width, closeTo(2 * BrandLogo.tipO, 2));
    expect(b.height, closeTo(2 * BrandLogo.tipO, 2));
    final bolt = BrandLogo.boltPath.getBounds();
    expect(bolt.top, lessThan(-BrandLogo.ringR));
    expect(bolt.bottom, greaterThan(BrandLogo.ringR));
  });
}
