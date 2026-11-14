// The golden ladder's input edges: a rung tapped before the catalog is built
// opens nothing (it used to open a legacy level and save under its old
// number), and Android back with a ladder card open closes the card instead
// of asking to leave the game. Idle/perf guards are in perf/ladder_perf_test.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/duty_slip/adventure_map.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_models.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/training/training_models.dart';
import 'package:slm_flutter/features/training/training_provider.dart';

ContentCatalog _catalog() => ContentCatalog.fromJson(
    jsonDecode(File('assets/game/catalog/content_catalog.json').readAsStringSync()) as Map<String, dynamic>);

final _opened = <int>[];
var _exitAsked = 0;

/// The ladder as DutySlipPage hosts it: under a PopScope that would ask
/// "leave the game?", asking the map to close a card first.
Future<void> _pump(WidgetTester t, {required Future<ContentCatalog> Function() catalog}) async {
  SharedPreferences.setMockInitialValues({});
  t.view.physicalSize = const Size(800, 1600);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  _opened.clear();
  _exitAsked = 0;
  final engine = DutySlipEngine(await DsPack.load(), seed: 7);
  await t.pumpWidget(ProviderScope(
    overrides: [
      contentCatalogProvider.overrideWith((ref) => catalog()),
      trainingLadderProvider.overrideWith((ref) async => <TrainingModuleItem>[]),
    ],
    child: MaterialApp(
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (did, _) {
          if (did || AdventureMap.closeOpenCard()) return;
          _exitAsked++;
        },
        child: Scaffold(
          body: AdventureMap(engine: engine, onOpen: _opened.add, scrollOut: ValueNotifier<double>(0), muted: true),
        ),
      ),
    ),
  ));
  // The guide's greeting and the pin scroll finish.
  for (var i = 0; i < 120; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _byType(String name) => find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

Future<void> _done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a rung tapped while the catalog loads opens nothing and saves nothing', (t) async {
    final never = Completer<ContentCatalog>();
    await _pump(t, catalog: () => never.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'still loading');
    await t.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_LevelCoin' && (w as dynamic).current == true));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(_byType('_NextRungPlayBar'));
    await t.pump(const Duration(milliseconds: 600));
    expect(_opened, isEmpty, reason: 'no legacy level');
    final save = ProviderScope.containerOf(t.element(find.byType(AdventureMap))).read(gameSaveProvider);
    expect(save.currentRungId, GameSave.empty.currentRungId, reason: 'no progress under an old level number');
    await _done(t);
  });

  testWidgets('back with a ladder card open closes the card, not the game', (t) async {
    await _pump(t, catalog: () async => _catalog());
    expect(AdventureMap.closeOpenCard(), isFalse, reason: 'no card open');
    // A Coming Soon rung (just past the 150 playable ones) answers with a card.
    final list = t.state<ScrollableState>(find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable))).position;
    list.jumpTo(list.maxScrollExtent);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_LevelCoin' && (w as dynamic).soon == true).first);
    await t.pump(const Duration(milliseconds: 300));
    expect(_byType('_KineticReply'), findsOneWidget);

    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 300));
    expect(_byType('_KineticReply'), findsNothing, reason: 'back closed the card');
    expect(_exitAsked, 0, reason: 'and did not ask to leave the game');

    await t.binding.handlePopRoute();
    await t.pump();
    expect(_exitAsked, 1, reason: 'with no card open, back asks as before');
    await _done(t);
  });
}
