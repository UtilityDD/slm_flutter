// Since 1c9e82d the right reason card zooms with its full text and waits for
// the player's এগিয়ে যান (key 'reason-proceed-btn') before the level moves on
// (GAME_LEVEL_PLAYBOOK.md §1, beat 6). The coworker's refuse/listen deck has no
// proceed: it closes by itself after the pick.
//
// Since 2026-11-12 a tap on a ChoiceDeck card only opens its preview; the
// pick is made with its ✓ (key 'choice-confirm'). [tapReasonProceed] confirms
// an open preview first, so "tap a card, then tapReasonProceed" still picks.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';

final _proceed = find.byKey(const ValueKey('reason-proceed-btn'));
final _confirm = find.byKey(const ValueKey('choice-confirm'));

/// If a card's preview is open, waits until its ✓ takes a tap (the preview
/// ignores taps while it opens) and taps it. True when a pick was confirmed.
Future<bool> confirmChoice(WidgetTester t, {int maxMs = 1500}) async {
  await t.pump();
  if (_confirm.evaluate().isEmpty) return false;
  for (var ms = 0; ms < maxMs && _confirm.hitTestable().evaluate().isEmpty; ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final ready = _confirm.hitTestable();
  if (ready.evaluate().isEmpty) return false;
  await t.tap(ready.first, warnIfMissed: false);
  await t.pump();
  return true;
}

/// Call right after tapping a card on a [ChoiceDeck]: confirms its preview
/// (✓), then, if it was a right reason, waits for the zoomed card and taps its
/// proceed button. If the deck closes without one (a coworker deck), returns
/// as soon as it is gone.
Future<void> tapReasonProceed(WidgetTester t, {int maxMs = 2000}) async {
  await confirmChoice(t);
  await t.pump();
  for (var ms = 0; ms < maxMs && _proceed.evaluate().isEmpty && find.byType(ChoiceDeck).evaluate().isNotEmpty; ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
  if (_proceed.evaluate().isNotEmpty) {
    await t.tap(_proceed, warnIfMissed: false);
    await t.pump();
  }
}

/// Picks the card that reads [text] on the [ChoiceDeck]: waits for the deck,
/// taps the card, confirms with ✓ and — unless [proceed] is false — taps the
/// right reason's এগিয়ে যান as [tapReasonProceed] does.
Future<void> pickChoice(WidgetTester t, String text, {bool proceed = true}) async {
  await waitChoiceDeck(t);
  final card = find.byKey(ValueKey('deal-$text'));
  expect(card, findsOneWidget, reason: 'no card "$text" on the deck');
  await t.tap(card, warnIfMissed: false);
  if (proceed) {
    await tapReasonProceed(t);
  } else {
    await confirmChoice(t);
  }
}

final _cards = find.descendant(
  of: find.byType(ChoiceDeck),
  matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.button ?? false)),
);

bool _deckReady() {
  final n = _cards.evaluate().length;
  return n > 0 && _cards.hitTestable().evaluate().length == n;
}

/// Pumps until a [ChoiceDeck] is up and its cards have slid in where a finger
/// can reach them (the coworker's beat 2 follows his line, and his caption is
/// held for a reading time when muted).
Future<void> waitChoiceDeck(WidgetTester t, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs && !_deckReady(); ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}
