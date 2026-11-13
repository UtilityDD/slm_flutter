import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'choice_deck.dart';
import 'gesture_hint.dart';
import 'learn_feedback_lines.dart';

// Level 1's success beat for any Do level (GAME_LEVEL_PLAYBOOK.md §1.6):
// a right move puts its ◆ on the table → praise → "কেন …?" with three cards →
// the right reason pays the table into the level score, a wrong one burns it
// (a right retry still pays 5) → the chosen card zooms with full text and a
// proceed button; the level moves only when the player taps proceed.
// A wrong reason is not a strike; the field mistakes are the strikes.
//
// From [ReasonTable.putOnTable] until the deck opens (the praise line + a
// breath) the scene takes no input: [FullSceneFrame] finds this mixin above it
// and shields its scene and overlays (the header's close and mute stay live).
// Levels gate their own handlers on [ReasonTable.tableBusy] as well, so a
// second tap in that window can never score twice or slip.

/// The reason pays what waited on the table; after a wrong reason burned it,
/// the right one still pays 5 (the level 1 rule).
int whyPayout({required int pending, required bool retried}) => pending > 0 ? pending : (retried ? 5 : 0);

/// Mix into a Do level's state; implement the hooks with the level's own
/// speech and score calls.
mixin ReasonTable<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  // --- hooks -----------------------------------------------------------------
  bool get reasonMuted;
  bool get reasonEnded;
  Future<void> reasonSay(List<String> lines, {GuideMood mood = GuideMood.talk});
  void reasonHush();

  /// Pay [delta] into the level score (the level's `_levelDelta`).
  Future<void> reasonScore(int delta, Offset origin, {GuideMood? mood});

  /// The right reason was paid and the player tapped proceed: move on.
  void onReasonPaid();

  // --- state -----------------------------------------------------------------
  int tablePending = 0;
  int _tableTok = 0;
  int _burnAmt = 0;
  int _burnTok = 0;
  var reasonOpen = false;
  /// Praise window: the ◆ is on the table, the deck is not up yet.
  var _tableHold = false;
  var _reasonBusy = false;
  var _reasonRetry = false;
  List<ChoiceOption> _reasonOpts = const [];
  final Set<String> _reasonWrong = {};
  String? _reasonPicked;
  /// Right card locked in: zoom + full text until proceed.
  var _reasonReveal = false;
  String _reasonRevealText = '';
  final _tokenKey = GlobalKey();
  final _praise = LineBag(LearnFeedbackLines.right);

  /// The options on the deck now (tests and taps).
  List<ChoiceOption> get reasonOptions => _reasonOpts;

  /// True while the zoomed proceed card is up (tests can wait on this).
  bool get reasonAwaitingProceed => _reasonReveal;

  /// The praise window: from [putOnTable] until the reason deck opens. The
  /// scene must take no input now ([FullSceneFrame] shields it by itself).
  bool get tableHolding => _tableHold && !reasonEnded;

  /// A right move is being rewarded: from [putOnTable] until the reason deck
  /// has closed ([proceedReason]). Gate the level's scene controls on it
  /// (`!tableBusy` in `_canPlay`); the deck itself stays live.
  bool get tableBusy => tableHolding || reasonOpen;

  /// A right move: its ◆ go on the table (call inside the level's setState
  /// or on its own — it sets state).
  void putOnTable(int amount) {
    setState(() {
      tablePending = amount;
      _tableHold = true;
      _tableTok++;
      _reasonRetry = false;
      _reasonWrong.clear();
      _reasonPicked = null;
      _reasonReveal = false;
      _reasonRevealText = '';
    });
  }

  /// Praise, then the reason cards are dealt and [question] is asked.
  /// [stillValid]: false when the level moved on meanwhile.
  Future<void> askReason({required List<ChoiceOption> Function() deal, required String question, bool Function()? stillValid}) async {
    await reasonSay([_praise.next().shownBn], mood: GuideMood.celebrate);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (reasonEnded || reasonOpen || (stillValid != null && !stillValid())) {
      if (_tableHold) setState(() => _tableHold = false);
      return;
    }
    setState(() {
      _reasonOpts = deal();
      _tableHold = false;
      reasonOpen = true;
      _reasonReveal = false;
      _reasonRevealText = '';
      _reasonPicked = null;
    });
    if (!reasonMuted) unawaited(ZlFx.cue('sounds/learn/card_deal_a.wav', volume: 0.6, muted: false));
    unawaited(reasonSay([question]));
  }

  Offset? _tokenCentre() {
    final box = _tokenKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// A reason card: the right one pays the table, a wrong one burns it.
  Future<void> pickReason(ChoiceOption opt, Offset origin) async {
    if (!reasonOpen || _reasonBusy || reasonEnded || _reasonReveal || _reasonWrong.contains(opt.textBn)) return;
    reasonHush();
    if (!opt.correct) {
      HapticFeedback.mediumImpact();
      if (!reasonMuted) unawaited(ZlFx.cue('sounds/quiz_wrong.wav', volume: 0.7, muted: false));
      final burnt = tablePending;
      setState(() {
        _reasonWrong.add(opt.textBn);
        _reasonRetry = true;
        if (burnt > 0) {
          _burnAmt = burnt;
          _burnTok++;
          tablePending = 0;
        }
      });
      if (burnt > 0 && !reasonMuted) unawaited(ZlFx.cue('sounds/dress_wrong.wav', volume: 0.7, muted: false));
      unawaited(reasonSay([LearnCoachLines.notThisReason], mood: GuideMood.warn));
      return;
    }
    _reasonBusy = true;
    final bank = whyPayout(pending: tablePending, retried: _reasonRetry);
    final from = _tokenCentre() ?? origin;
    setState(() {
      _reasonPicked = opt.textBn;
      _reasonRevealText = opt.textBn;
      _reasonReveal = true;
      tablePending = 0;
    });
    HapticFeedback.lightImpact();
    if (!reasonMuted) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.8, muted: false));
      unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.7, muted: false));
    }
    await reasonScore(bank, from, mood: GuideMood.celebrate);
    if (!mounted || !_reasonReveal) return;
    await reasonSay([LearnCoachLines.realPoint], mood: GuideMood.glad);
    if (!mounted || !_reasonReveal) return;
    setState(() => _reasonBusy = false);
    // Stay on the zoomed card until [proceedReason].
  }

  /// Player confirmed the zoomed reason — close the deck and advance.
  /// Allowed even while praise still plays (cuts the line and moves on).
  void proceedReason() {
    if (!_reasonReveal || reasonEnded) return;
    reasonHush();
    HapticFeedback.selectionClick();
    if (!reasonMuted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.55, muted: false));
    setState(() {
      reasonOpen = false;
      _tableHold = false;
      _reasonReveal = false;
      _reasonBusy = false;
      _reasonPicked = null;
      _reasonRevealText = '';
    });
    onReasonPaid();
  }

  /// The reason deck (place it on the scene's bottom edge).
  Widget reasonDeck({required bool quiet, Key? key}) {
    if (_reasonReveal) {
      return _ReasonProceedCard(
        key: key ?? const ValueKey('reason-proceed'),
        textBn: _reasonRevealText,
        quiet: quiet,
        muted: reasonMuted,
        onProceed: proceedReason,
      );
    }
    return ChoiceDeck(
      key: key,
      options: _reasonOpts,
      quiet: quiet,
      muted: reasonMuted,
      wrong: _reasonWrong,
      picked: _reasonPicked,
      onPick: (o, at) => unawaited(pickReason(o, at)),
    );
  }

  /// The ◆ waiting on the table, and burnt ◆ flying off, centred at [at].
  List<Widget> tableLayers({required Offset at, required bool quiet}) => [
        if (tablePending > 0)
          Positioned(
            key: const ValueKey('hud-token'),
            left: at.dx - 44,
            top: at.dy - 18,
            width: 88,
            height: 36,
            child: KeyedSubtree(
              key: _tokenKey,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('tok-$_tableTok'),
                tween: Tween(begin: quiet ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.elasticOut,
                builder: (_, t, child) => Transform.scale(scale: t, child: child),
                child: TablePill(amount: tablePending),
              ),
            ),
          ),
        if (_burnAmt > 0)
          Positioned(
            key: const ValueKey('hud-burn'),
            left: at.dx - 44,
            top: at.dy - 18,
            width: 88,
            height: 36,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('burn-$_burnTok'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: quiet ? 1 : 800),
              onEnd: () {
                if (mounted) setState(() => _burnAmt = 0);
              },
              builder: (_, t, child) => Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(0, -24 * t), child: Transform.scale(scale: 1 - 0.4 * t, child: child)),
              ),
              child: TablePill(amount: _burnAmt, burnt: true),
            ),
          ),
      ];
}

/// The ◆ waiting on the table for the reason (grey and red when burnt).
class TablePill extends StatelessWidget {
  const TablePill({super.key, required this.amount, this.burnt = false});
  final int amount;
  final bool burnt;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: burnt ? const [Color(0xFF6B2A22), Color(0xFF3A1C18)] : const [Color(0xFFFFD34E), Color(0xFFF2A51A)]),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: burnt ? const Color(0xFFC0392B) : const Color(0xFFFFF3C4), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Text('◆ +$amount',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: burnt ? const Color(0xFFF3B9B0) : const Color(0xFF3A2500))),
    );
  }
}

/// Zoomed right-reason card with full text and a single proceed control.
class _ReasonProceedCard extends StatelessWidget {
  const _ReasonProceedCard({
    super.key,
    required this.textBn,
    required this.quiet,
    required this.muted,
    required this.onProceed,
  });

  final String textBn;
  final bool quiet;
  final bool muted;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    // Stuck on the zoomed card: the hand taps the one button (how, not what).
    return IdleHint(
      waiting: true,
      waitKey: textBn,
      spec: (size) => HintSpec.tap(Offset(size.width / 2, size.height - 14 - 25), space: HintSpace.local),
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    // Never taller than the screen under the header: a long reason scrolls
    // inside the card and এগিয়ে যান stays in reach (320×568, landscape).
    final mq = MediaQuery.of(context);
    final maxH = math.max(160.0, mq.size.height - mq.padding.top - mq.padding.bottom - 54 - 12);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0.82, end: 1),
      duration: Duration(milliseconds: quiet ? 1 : 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: t, alignment: Alignment.bottomCenter, child: child),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxH),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SlmColors.navy800.withValues(alpha: 0.98), SlmColors.navy950],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
            top: BorderSide(color: SlmColors.emerald400.withValues(alpha: 0.7), width: 1.6),
          ),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 22, offset: Offset(0, -6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SlmColors.emerald500.withValues(alpha: 0.28),
                    border: Border.all(color: SlmColors.emerald400),
                  ),
                  child: const Icon(Icons.check_rounded, size: 22, color: SlmColors.emerald300),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ঠিক কারণ',
                    style: bangla(fontSize: 14, fontWeight: FontWeight.w800, color: SlmColors.emerald300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  enDigits(textBn),
                  style: bangla(fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.4, color: SlmColors.ivory),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: SlmColors.emerald500,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                key: const ValueKey('reason-proceed-btn'),
                borderRadius: BorderRadius.circular(16),
                onTap: onProceed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'এগিয়ে যান',
                      style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.navy950),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
