// Levels open with the guide (as level 1): no start button, no skipping —
// the game begins once he has said the task. Tests wait for that.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/scene_kit.dart';

bool _introUp() =>
    find.byType(LevelIntro).evaluate().isNotEmpty ||
    find.byType(GuideIntro).evaluate().isNotEmpty ||
    find.byType(GuidedTour).evaluate().isNotEmpty;

/// Pumps until the guide's opening (intro, guide-first screen or tour) is
/// over; a tour beat that waits for a tap on the scene gets it.
Future<void> waitIntro(WidgetTester t, {int maxMs = 60000}) async {
  for (var ms = 0; ms < maxMs && _introUp(); ms += 100) {
    final look = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'দেখুন');
    if (look.evaluate().isNotEmpty) await t.tap(look.first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 100));
  }
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}
