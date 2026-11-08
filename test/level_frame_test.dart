// The shared level frame: the guide's intro comes first; three small mistakes
// fail the level with the lesson card, and playing again opens up only after
// reading (or the offline fallback); the header shows only the ladder step.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/rod_pick.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '1.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: '',
  ladderStep: 14,
  doIndex: 1,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
  }
  ZlFx.setMuted(true);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpokenOnce.resetForTest();
  });

  testWidgets('intro first, header shows only the step; three slips fail the level and the lesson card insists', (t) async {
    t.view.physicalSize = const Size(720, 1600);
    t.view.devicePixelRatio = 2.0;
    final c = ProviderContainer();
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ));
    unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
      builder: (_) => RodPickPage(ctx: _ctx, pack: rodPickPack15, muted: true, seed: 4),
    )));
    await _pump(t, 400);

    // The guide's intro covers the game (as level 1: no start button, a tap
    // does not skip); the game begins once he has said the task.
    expect(find.byType(GuideIntro), findsOneWidget);
    expect(find.text('শুরু'), findsNothing, reason: 'no start button');
    expect(find.text('ধাপ 14'), findsOneWidget);
    expect(find.text('পাঠ 1.5 · কাজ 1/2'), findsNothing, reason: 'lesson numbers stay internal');
    await t.tapAt(const Offset(360, 800));
    await _pump(t, 600);
    expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
    await waitIntro(t);
    expect(find.byType(GuideIntro), findsNothing);

    // Tap the guide (as level 1): he says the task again, a different way each time.
    final coach = t.getRect(find.byType(AiLinemanGuide).last).bottomRight - const Offset(50, 50);
    final heard = <String>{};
    for (var i = 0; i < 2; i++) {
      await t.tapAt(coach);
      await _pump(t, 200);
      final line = c.read(guideDirectorProvider).line;
      expect(line, contains(RodLines.ask));
      heard.add(line);
    }
    expect(heard.length, 2, reason: 'a different way each time');

    // Docket 1 has a right rod, so holding the job is a slip — three times.
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(RodLines.hold));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
    }
    await t.tap(find.text(RodLines.hold));
    await _pump(t, 800);
    expect(find.text(FrameLines.struckHead), findsOneWidget);
    expect(find.text(MistakeLines.slipHead), findsNothing);
    expect(c.read(gameSaveProvider).levelScoreByRung.containsKey('1.5/do/0'), isTrue);

    // "আবার খেলি" is locked until the lesson is read (offline: a fallback timer).
    await t.tap(find.text(FrameLines.again));
    await _pump(t, 400);
    expect(find.text(FrameLines.struckHead), findsOneWidget, reason: 'locked before reading');
    await _pump(t, 12500);
    await t.tap(find.text(FrameLines.again));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.text(FrameLines.struckHead), findsNothing);
    expect(find.byType(GuideIntro), findsOneWidget, reason: 'a fresh play starts with the intro');
    expect(t.takeException(), isNull);

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    MascotTalk.reset();
    c.dispose();
    t.view.reset();
  });
}
