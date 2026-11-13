// Step 3 (গ্লাভস যাচাই) on the shared level kit: an air-tested sound pair
// packed puts its ◆ on the table and "কেন এই জোড়াটা নিলেন?" follows; the
// careless coworker peeps in before the push round; the libraries are fair.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/glove_check.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '1.1/do/1', kind: CatalogRungKind.doKind, lessonId: '1.1', lessonTitleBn: '', ladderStep: 3, doIndex: 2, doCount: 2);

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

void main() {
  test('step 3 libraries: same length, big enough; his lines are in his recorded voice', () {
    expectSameLength('why', [...GloveLines.whyRight, ...GloveLines.whyWrong]);
    expectLibrary('why', GloveLines.whyRight, GloveLines.whyWrong);
    expectSameLength('choice', [...GloveLines.choiceRight, ...GloveLines.choiceWrong]);
    expectLibrary('choice', GloveLines.choiceRight, GloveLines.choiceWrong);
    for (final c in [GloveLines.coworkerNew, GloveLines.coworkerTrip]) {
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

    testWidgets('air-test and pack your own pair → ◆ on the table → the reason; the coworker before the push round', (t) async {
      // A play whose push comes before the partner's pair (round 1).
      var seed = 0;
      while (dealGloves(gloveCheckPack11, math.Random(seed)).callBefore != 1) {
        seed++;
      }
      final rng = math.Random(seed);
      final deal = dealGloves(gloveCheckPack11, rng);
      final first = [...deal.rounds.first]..shuffle(rng);
      final good = first.indexWhere((g) => g.kind == GloveKind.good);
      expect(good, isNonNegative);

      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: GloveCheckPage(ctx: _ctx, pack: gloveCheckPack11, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await _pump(t, 1500);

      await t.tap(_cards.at(good));
      await _pump(t, 400);
      final g = await t.startGesture(t.getCenter(find.text(GloveLines.testButton)));
      for (var k = 0; k < 24; k++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await g.up();
      await _pump(t, 400);
      expect(find.text(GloveLines.holds), findsWidgets);
      await t.tap(find.text('নিয়ে নিন'));
      await _pump(t, 3500);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the reason deck after a pair packed');
      final right = _onScreen(GloveLines.whyRight);
      expect(right, hasLength(1));
      await t.tap(right.single, warnIfMissed: false);
      await confirmChoice(t);
      await t.pump();
      await t.tap(find.byKey(const ValueKey('reason-proceed-btn')), warnIfMissed: false);
      await _pump(t, 2500);
      expect(_onScreen([...GloveLines.whyRight, ...GloveLines.whyWrong]), isEmpty, reason: 'the reason was paid');

      // The partner's pair: the coworker peeps in; the guide asks; refuse him.
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final refuse = _onScreen(GloveLines.choiceRight);
      expect(refuse, hasLength(1));
      await t.tap(refuse.single, warnIfMissed: false);
      await confirmChoice(t);
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
