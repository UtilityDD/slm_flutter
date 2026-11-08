import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guide/guide_director.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'choice_deck.dart';
import 'learn_feedback_lines.dart';

// Level 1's success beat for any Do level (GAME_LEVEL_PLAYBOOK.md §1.6):
// a right move puts its ◆ on the table → praise → "কেন …?" with three cards →
// the right reason pays the table into the level score, a wrong one burns it
// (a right retry still pays 5) → the level moves on by itself.
// A wrong reason is not a strike; the field mistakes are the strikes.

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

  /// The right reason was paid: move on (next round, or the result).
  void onReasonPaid();

  // --- state -----------------------------------------------------------------
  int tablePending = 0;
  int _tableTok = 0;
  int _burnAmt = 0;
  int _burnTok = 0;
  var reasonOpen = false;
  var _reasonBusy = false;
  var _reasonRetry = false;
  List<ChoiceOption> _reasonOpts = const [];
  final Set<String> _reasonWrong = {};
  String? _reasonPicked;
  final _tokenKey = GlobalKey();
  final _praise = LineBag(LearnFeedbackLines.right);

  /// The options on the deck now (tests and taps).
  List<ChoiceOption> get reasonOptions => _reasonOpts;

  /// A right move: its ◆ go on the table (call inside the level's setState
  /// or on its own — it sets state).
  void putOnTable(int amount) {
    setState(() {
      tablePending = amount;
      _tableTok++;
      _reasonRetry = false;
      _reasonWrong.clear();
      _reasonPicked = null;
    });
  }

  /// Praise, then the reason cards are dealt and [question] is asked.
  /// [stillValid]: false when the level moved on meanwhile.
  Future<void> askReason({required List<ChoiceOption> Function() deal, required String question, bool Function()? stillValid}) async {
    await reasonSay([_praise.next().shownBn], mood: GuideMood.celebrate);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || reasonEnded || reasonOpen || (stillValid != null && !stillValid())) return;
    setState(() {
      _reasonOpts = deal();
      reasonOpen = true;
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
    if (!reasonOpen || _reasonBusy || reasonEnded || _reasonWrong.contains(opt.textBn)) return;
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
    // The right card stays green a moment, however fast the rest goes.
    final dwell = Future<void>.delayed(const Duration(milliseconds: 900));
    final bank = whyPayout(pending: tablePending, retried: _reasonRetry);
    final from = _tokenCentre() ?? origin;
    setState(() {
      _reasonPicked = opt.textBn;
      tablePending = 0;
    });
    HapticFeedback.lightImpact();
    if (!reasonMuted) {
      unawaited(ZlFx.cue('sounds/quiz_right.wav', volume: 0.8, muted: false));
      unawaited(ZlFx.cue('sounds/intro/confirm.ogg', volume: 0.7, muted: false));
    }
    await reasonScore(bank, from, mood: GuideMood.celebrate);
    if (!mounted) return;
    await reasonSay([LearnCoachLines.realPoint], mood: GuideMood.glad);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await dwell;
    if (!mounted || reasonEnded) return;
    setState(() {
      reasonOpen = false;
      _reasonBusy = false;
    });
    onReasonPaid();
  }

  /// The reason deck (place it on the scene's bottom edge).
  Widget reasonDeck({required bool quiet, Key? key}) => ChoiceDeck(
        key: key,
        options: _reasonOpts,
        quiet: quiet,
        muted: reasonMuted,
        wrong: _reasonWrong,
        picked: _reasonPicked,
        onPick: (o, at) => unawaited(pickReason(o, at)),
      );

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
