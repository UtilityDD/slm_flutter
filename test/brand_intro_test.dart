// The brand splash over the app (drawn in code): the lockup beat plays once
// with its sound and fades into the app within 1.5 s; a tap anywhere, reduced
// motion and a missing sound all end in the app; the drawing paints at every
// moment of its timeline.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/startup/brand_intro.dart';

class _Sound implements IntroSound {
  var played = 0, stopped = 0;
  Duration? from;
  @override
  Future<void> play({Duration from = Duration.zero}) async {
    played++;
    this.from = from;
  }

  @override
  Future<void> stop() async => stopped++;
}

Widget _app(IntroSound sound, {Future<void> Function(BuildContext)? warmUp}) => MaterialApp(
      home: IntroGate(sound: sound, warmUp: warmUp, child: const Scaffold(body: Text('app'))),
    );

void main() {
  testWidgets('plays once with its sound from the lockup, gone within 1.5 s', (t) async {
    final s = _Sound();
    await t.pumpWidget(_app(s));
    expect(find.byType(IntroOverlay), findsOneWidget);
    await t.pump();
    expect(s.played, 1);
    expect(s.from, Duration(milliseconds: (IntroOverlay.from * 1000).round()));
    await t.pump(const Duration(milliseconds: 800));
    expect(find.byType(IntroOverlay), findsOneWidget, reason: 'still playing at 0.8 s');
    // Frame by frame, as a phone: the layer must be gone by 1.5 s.
    for (var ms = 800; ms < IntroOverlay.total.inMilliseconds + 32; ms += 16) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(IntroOverlay), findsNothing);
    expect(find.text('app'), findsOneWidget);
    expect(s.stopped, 0, reason: 'the last hit plays on as the app appears');
  });

  testWidgets('a tap anywhere stops the sound and leaves at once', (t) async {
    final s = _Sound();
    await t.pumpWidget(_app(s));
    await t.pump(const Duration(milliseconds: 100));
    await t.tapAt(const Offset(40, 300));
    await t.pump();
    await t.pump(IntroOverlay.fade + const Duration(milliseconds: 50));
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
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing, reason: 'Home shows while the warm-up runs on');
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
