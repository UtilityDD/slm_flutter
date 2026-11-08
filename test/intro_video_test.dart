// The brand intro over the app: it never blocks the app — a video that cannot
// load, a load that hangs, reduced motion and the skip chip all end in the app.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/startup/intro_video.dart';
import 'package:video_player/video_player.dart';

Widget _app(IntroVideoLoader loader) => MaterialApp(
      home: IntroGate(loader: loader, child: const Scaffold(body: Text('app'))),
    );

void main() {
  testWidgets('shows the navy and the logo first, then the app when the video cannot load', (t) async {
    await t.pumpWidget(_app(() async => null));
    expect(find.byType(IntroOverlay), findsOneWidget);
    expect(find.image(const AssetImage(IntroGate.logoAsset)), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('a load that hangs gives up after the timeout', (t) async {
    final never = Completer<VideoPlayerController?>();
    await t.pumpWidget(_app(() => never.future));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(IntroOverlay), findsOneWidget);
    await t.pump(IntroGate.loadTimeout);
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing);
  });

  testWidgets('reduced motion skips the video', (t) async {
    var asked = false;
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _app(() async {
        asked = true;
        return null;
      }),
    ));
    await t.pumpAndSettle();
    expect(asked, isFalse);
    expect(find.byType(IntroOverlay), findsNothing);
  });

  testWidgets('the warm-up starts with the intro and runs on after it', (t) async {
    final warm = Completer<void>();
    var started = 0;
    await t.pumpWidget(MaterialApp(
      home: IntroGate(
        loader: () async => null,
        warmUp: (_) {
          started++;
          return warm.future;
        },
        child: const Text('app'),
      ),
    ));
    await t.pump();
    expect(started, 1);
    await t.pumpAndSettle();
    expect(find.byType(IntroOverlay), findsNothing, reason: 'the app does not wait for the warm-up');
    warm.complete();
  });

  testWidgets('disabled: no warm-up either', (t) async {
    var started = 0;
    await t.pumpWidget(MaterialApp(
      home: IntroGate(
        enabled: false,
        warmUp: (_) async => started++,
        child: const Text('app'),
      ),
    ));
    await t.pump();
    expect(started, 0);
  });

  testWidgets('disabled: the app straight away', (t) async {
    await t.pumpWidget(const MaterialApp(home: IntroGate(enabled: false, child: Text('app'))));
    expect(find.byType(IntroOverlay), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}
