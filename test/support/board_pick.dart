// Learn picture boards (LearnBoardRunnerPage): a tap on a card only opens it
// large; ✓ "বেছে নিন" chooses it, ✕ "বাদ দিন" sets it aside, and the
// feedback waits under the card for "এগিয়ে যান". Tests go through these.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final boardConfirm = find.byKey(const ValueKey('board-choice-confirm'));
final boardReject = find.byKey(const ValueKey('board-choice-reject'));
final boardContinue = find.byKey(const ValueKey('board-choice-continue'));
final boardPreview = find.byKey(const ValueKey('board-choice-preview'));
final boardFeedback = find.byKey(const ValueKey('board-choice-feedback'));

Future<void> _until(WidgetTester t, Finder f, int maxMs, String what) async {
  for (var ms = 0; ms < maxMs; ms += 50) {
    if (f.evaluate().isNotEmpty) return;
    await t.pump(const Duration(milliseconds: 50));
  }
  fail('timed out waiting for $what');
}

/// Taps [card] and waits until its preview has landed (✓ / ✕ take taps).
Future<void> openBoardCard(WidgetTester t, Finder card) async {
  await t.tap(card.first, warnIfMissed: false);
  await t.pump();
  await _until(t, boardConfirm, 3000, 'the card preview');
  // The opening pop (260 ms) ignores taps.
  await t.pump(const Duration(milliseconds: 320));
}

/// Opens [card] and chooses it (✓). The feedback then waits for [continueBoard].
Future<void> tapBoardCard(WidgetTester t, Finder card) async {
  await openBoardCard(t, card);
  await t.tap(boardConfirm, warnIfMissed: false);
  await t.pump();
}

/// Presses "এগিয়ে যান" once the feedback is up.
Future<void> continueBoard(WidgetTester t, {int maxMs = 15000}) async {
  await _until(t, boardContinue, maxMs, 'the Continue button');
  // A tap right after ✓ is ignored (double-tap guard).
  await t.pump(const Duration(milliseconds: 400));
  await t.tap(boardContinue, warnIfMissed: false);
  await t.pump();
}

/// Chooses [card] and moves on past its feedback.
Future<void> pickBoardCard(WidgetTester t, Finder card) async {
  await tapBoardCard(t, card);
  await continueBoard(t);
}

/// For retry loops: taps [card]; when its preview opens, chooses it (✓) and
/// returns true. False when the board ignored the tap (a scripted beat, or
/// [card] is not a board card).
Future<bool> tryTapBoardCard(WidgetTester t, Finder card) async {
  if (card.evaluate().isEmpty) return false;
  await t.tap(card.first, warnIfMissed: false);
  await t.pump();
  for (var ms = 0; ms < 600 && boardConfirm.evaluate().isEmpty; ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
  if (boardConfirm.evaluate().isEmpty) return false;
  await t.pump(const Duration(milliseconds: 320));
  await t.tap(boardConfirm, warnIfMissed: false);
  await t.pump();
  return true;
}

/// [tryTapBoardCard], then past the feedback when the card was taken.
Future<bool> tryPickBoardCard(WidgetTester t, Finder card) async {
  if (!await tryTapBoardCard(t, card)) return false;
  await continueBoard(t);
  return true;
}
