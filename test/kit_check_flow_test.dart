// Kit-check flow never holds the player: a tap on the shade puts an item back,
// a tap on a decided card moves on at once, and the next pick works right away.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/kit_check.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _ctx = LevelContext(
  rungId: '1.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.1',
  lessonTitleBn: '',
  ladderStep: 2,
  doIndex: 1,
  doCount: 2,
);

final _cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard');
final _inspect = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_InspectCard');

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

  testWidgets('put back, decide, tap to move on, pick again — no waiting on the coach', (t) async {
    SharedPreferences.setMockInitialValues({});
    SpokenOnce.resetForTest();
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    await t.pumpWidget(const ProviderScope(
      child: MaterialApp(home: KitCheckPage(ctx: _ctx, pack: kitCheckPack11, muted: true, seed: 3)),
    ));
    await _pump(t, 3000);
    expect(_cards, findsWidgets);

    // Tap the shade before deciding: the item goes back.
    await t.tap(_cards.first);
    await _pump(t, 500);
    expect(_inspect, findsOneWidget);
    await t.tapAt(const Offset(20, 120));
    await _pump(t, 300);
    expect(_inspect, findsNothing, reason: 'tapping the shade puts the item back');

    // Decide, then tap the card: it leaves well before the 1.4 s hold.
    final before = _cards.evaluate().length;
    await t.tap(_cards.first);
    await _pump(t, 500);
    await t.tap(find.text('বাদ দিন'));
    await _pump(t, 200);
    await t.tap(_inspect, warnIfMissed: false);
    await _pump(t, 700);
    expect(_inspect, findsNothing, reason: 'a tap moves on without waiting');

    // The next pick works at once.
    expect(_cards, findsWidgets);
    await t.tap(_cards.first);
    await _pump(t, 400);
    expect(_inspect, findsOneWidget, reason: 'the player is never locked out');
    expect(_cards.evaluate().length, lessThanOrEqualTo(before));
    expect(t.takeException(), isNull);

    MascotTalk.reset();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
    t.view.reset();
  });
}
