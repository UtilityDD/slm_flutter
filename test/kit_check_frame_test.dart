// Step 2 (কবচ যাচাই) on the shared level kit: a piece worn right puts its ◆
// on the table and "কেন এটা পরলেন?" follows; the careless coworker peeps in
// before the push slot and the guide asks; the option libraries are fair.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/kit_check.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(rungId: '1.1/do/0', kind: CatalogRungKind.doKind, lessonId: '1.1', lessonTitleBn: '', ladderStep: 2, doIndex: 1, doCount: 2);

final _cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard');

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// The tray order the page shows for [seed] (it deals, then shuffles).
List<KitItem> _trayFor(int seed, KitSlot slot) {
  final rng = math.Random(seed);
  final deal = dealKit(kitCheckPack11, rng);
  final order = [...deal.items]..shuffle(rng);
  return [for (final i in order) if (i.slot == slot) i];
}

/// Pick the sound item of [slot] and wear it.
Future<void> _wearGood(WidgetTester t, int seed, KitSlot slot) async {
  final tray = _trayFor(seed, slot);
  final at = tray.indexWhere((i) => i.kind == KitKind.good);
  await t.tap(_cards.at(at));
  await _pump(t, 500);
  await t.tap(find.text('পরে নিন'));
  await _pump(t, 200);
}

void main() {
  test('step 2 libraries: same length, big enough; his lines are in his recorded voice', () {
    for (final s in KitSlot.values) {
      expectSameLength('why ${s.name}', [...KitLines.whyRight(s), ...KitLines.whyWrong(s)]);
      expectLibrary('why ${s.name}', KitLines.whyRight(s), KitLines.whyWrong(s));
    }
    expectSameLength('choice', [...KitLines.choiceRight, ...KitLines.choiceWrong]);
    expectLibrary('choice', KitLines.choiceRight, KitLines.choiceWrong);
    for (final c in [KitLines.coworkerHurry, KitLines.coworkerVan]) {
      for (final l in c.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
    }
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);

    testWidgets('wear the shirt → ◆ on the table → the reason → the next piece; the coworker before the push slot', (t) async {
      // A play whose push comes before the trousers.
      var seed = 0;
      while (dealKit(kitCheckPack11, math.Random(seed)).callBefore != KitSlot.legs) {
        seed++;
      }
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: KitCheckPage(ctx: _ctx, pack: kitCheckPack11, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await _pump(t, 1500);

      await _wearGood(t, seed, KitSlot.torso);
      await _pump(t, 3000);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the reason deck after a piece worn right');
      final right = _onScreen(KitLines.whyRight(KitSlot.torso));
      expect(right, hasLength(1));
      await t.tap(right.single, warnIfMissed: false);
      await _pump(t, 2500);
      expect(_onScreen([...KitLines.whyTorsoRight, ...KitLines.whyTorsoWrong]), isEmpty, reason: 'the reason was paid');

      // The trousers: the coworker peeps in; the guide asks; refuse him.
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final refuse = _onScreen(KitLines.choiceRight);
      expect(refuse, hasLength(1));
      await t.tap(refuse.single, warnIfMissed: false);
      await _pump(t, 1800);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(t.takeException(), isNull);

      MascotTalk.reset();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      t.view.reset();
    });
  });
}
