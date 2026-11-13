import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart';
import 'gesture_hint.dart';

// Answer cards in level 1's style, for any level: a dark sheet rises from the
// bottom and the cards slide in from the right one after another (card
// sounds), each numbered; a card presses down under the finger; a wrong one
// shakes and turns red, the right one pops green. One-shot motion only —
// nothing loops while the player thinks. If the player seems stuck while the
// deck waits, a gesture hint sweeps a hand over the open cards (never
// pressing one) — how to answer, not which answer (gesture_hint.dart).
//
// Two steps, so a stray touch never answers (owner's brief 2026-11-12): a tap
// on a card only opens it big — its full text, the deck's navy and gold — with
// ✕ বাদ দিন and ✓ বেছে নিন, the same two buttons for every card (nothing about
// the card's correctness shows). ✕ closes it and sets the card aside (dimmed,
// struck, grey — not the red of a wrong card); it can be opened and chosen
// later. Only ✓ calls [ChoiceDeck.onPick]; the buttons take no tap while the
// preview opens (a double tap on a card can't confirm it). Idle on the
// preview, the hand sweeps over both buttons as a pair — never one alone.

@immutable
class ChoiceOption {
  const ChoiceOption(this.textBn, this.correct);
  final String textBn;
  final bool correct;
}

/// Deals one right and [wrongCount] wrong options from the libraries, in a
/// random order (so plays don't repeat).
List<ChoiceOption> dealChoices(List<String> right, List<String> wrong, math.Random rng, {int wrongCount = 2}) {
  final w = [...wrong]..shuffle(rng);
  return [
    ChoiceOption(right[rng.nextInt(right.length)], true),
    for (final t in w.take(wrongCount)) ChoiceOption(t, false),
  ]..shuffle(rng);
}

/// Words on the card preview (fixed, so they can be recorded later).
abstract final class ChoiceDeckLines {
  static const confirm = 'বেছে নিন';
  static const reject = 'বাদ দিন';
  static const asideTag = 'বাদ রাখা';
}

/// The sheet with the dealt cards. [wrong]: options already tried and wrong
/// (red, shaken, no longer tappable); [picked]: the right one, once chosen.
/// A tap opens a card's preview; only its ✓ (key `choice-confirm`) calls
/// [onPick]; its ✕ (key `choice-reject`) sets the card aside.
class ChoiceDeck extends StatefulWidget {
  const ChoiceDeck({
    super.key,
    required this.options,
    required this.onPick,
    required this.quiet,
    required this.muted,
    this.wrong = const {},
    this.picked,
  });

  final List<ChoiceOption> options;
  final void Function(ChoiceOption option, Offset origin) onPick;
  final bool quiet;
  final bool muted;
  final Set<String> wrong;
  final String? picked;

  /// The preview's buttons take taps only after this (its open motion).
  static const armDelay = Duration(milliseconds: 300);

  @override
  State<ChoiceDeck> createState() => _ChoiceDeckState();
}

class _ChoiceDeckState extends State<ChoiceDeck> {
  final _cardKeys = <String, GlobalKey>{};
  final _confirmBox = GlobalKey();
  final _rejectBox = GlobalKey();

  /// Cards the player set aside with ✕ (still open to choose).
  final _aside = <String>{};

  /// The card open in the preview, and where it was tapped (the pick's origin).
  String? _preview;
  Offset _previewAt = Offset.zero;

  /// The preview's buttons take taps (after [ChoiceDeck.armDelay]).
  var _armed = false;
  Timer? _arm;

  GlobalKey _keyFor(String text) => _cardKeys.putIfAbsent(text, GlobalKey.new);

  bool get _locked => widget.picked != null;

  @override
  void didUpdateWidget(ChoiceDeck old) {
    super.didUpdateWidget(old);
    final texts = {for (final o in widget.options) o.textBn};
    _aside.removeWhere((t) => !texts.contains(t) || widget.wrong.contains(t));
    final p = _preview;
    if (p != null && (_locked || !texts.contains(p) || widget.wrong.contains(p))) _closePreview();
  }

  @override
  void dispose() {
    _arm?.cancel();
    super.dispose();
  }

  void _closePreview() {
    _arm?.cancel();
    _preview = null;
    _armed = false;
  }

  /// A tap on a card: open it big (never an answer by itself).
  void _open(ChoiceOption o, Offset at) {
    if (_locked || widget.wrong.contains(o.textBn) || _preview != null) return;
    if (!widget.muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
    _arm?.cancel();
    setState(() {
      _preview = o.textBn;
      _previewAt = at;
      _armed = false;
    });
    _arm = Timer(ChoiceDeck.armDelay, () {
      if (mounted && _preview != null) setState(() => _armed = true);
    });
  }

  /// ✓ — the card is the player's answer.
  void _confirm() {
    final p = _preview;
    if (!_armed || p == null || _locked) return;
    ChoiceOption? o;
    for (final c in widget.options) {
      if (c.textBn == p) o = c;
    }
    if (o == null) return;
    HapticFeedback.selectionClick();
    if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/click.ogg', volume: 0.55, muted: false));
    setState(() {
      _closePreview();
      _aside.remove(p);
    });
    widget.onPick(o, _previewAt);
  }

  /// ✕ — not this one (for now): set it aside, nothing is answered.
  void _reject() {
    final p = _preview;
    if (!_armed || p == null) return;
    if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.45, muted: false));
    setState(() {
      _closePreview();
      _aside.add(p);
    });
  }

  /// The open cards (not yet tried), for the sweep hint. With one card left
  /// there is no hint: a sweep over one card would point at the answer. On
  /// the preview the hand sweeps over both of its buttons (a pair, always).
  HintSpec? _hint() {
    if (_preview != null) return _armed ? HintSpec.sweepOver([_rejectBox, _confirmBox]) : null;
    final open = [
      for (final o in widget.options)
        if (!widget.wrong.contains(o.textBn)) _keyFor(o.textBn),
    ];
    return open.length < 2 ? null : HintSpec.sweepOver(open);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    _cardKeys.removeWhere((k, _) => !options.any((o) => o.textBn == k));
    final preview = _preview;
    return IdleHint(
      waiting: widget.picked == null && options.isNotEmpty,
      waitKey: preview == null ? options.map((o) => o.textBn).join('|') : 'preview|$preview|$_armed',
      spec: (_) => _hint(),
      child: _sheet(context),
    );
  }

  /// The tallest the preview may be: the screen under the header, less the
  /// sheet's own edges; never more than ~2/3 of the screen (the scene stays).
  double _previewMaxHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final room = h - mq.padding.top - mq.padding.bottom - 54 - 12 - 40;
    return math.max(150.0, math.min(room, math.max(220.0, h * 0.62)));
  }

  Widget _sheet(BuildContext context) {
    final options = widget.options;
    final quiet = widget.quiet;
    final wrong = widget.wrong;
    final picked = widget.picked;
    final preview = _preview;
    final previewIndex = preview == null ? -1 : options.indexWhere((o) => o.textBn == preview);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: quiet ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Transform.translate(offset: Offset(0, 40 * (1 - t)), child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SlmColors.navy900.withValues(alpha: 0.94), SlmColors.navy950.withValues(alpha: 0.98)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.45), width: 1.4)),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: SlmColors.gold400.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
            ),
            // The cards stay mounted under the preview (no re-deal when it closes).
            Offstage(
              offstage: preview != null && previewIndex >= 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _DealtCard(
                      key: ValueKey('deal-${options[i].textBn}'),
                      boxKey: _keyFor(options[i].textBn),
                      index: i,
                      option: options[i],
                      quiet: quiet,
                      muted: widget.muted,
                      wrong: wrong.contains(options[i].textBn),
                      right: picked == options[i].textBn,
                      aside: _aside.contains(options[i].textBn) && !wrong.contains(options[i].textBn),
                      onOpen: _open,
                    ),
                  ],
                ],
              ),
            ),
            if (preview != null && previewIndex >= 0)
              _ChoicePreview(
                key: ValueKey('choice-preview-$preview'),
                index: previewIndex,
                textBn: preview,
                quiet: quiet,
                armed: _armed,
                maxHeight: _previewMaxHeight(context),
                confirmBox: _confirmBox,
                rejectBox: _rejectBox,
                onConfirm: _confirm,
                onReject: _reject,
              ),
          ],
        ),
      ),
    );
  }
}

/// A card opened big: its number, its full text (scrolls inside if long) and
/// the two buttons — the same for every card, so nothing gives the answer away.
class _ChoicePreview extends StatelessWidget {
  const _ChoicePreview({
    super.key,
    required this.index,
    required this.textBn,
    required this.quiet,
    required this.armed,
    required this.maxHeight,
    required this.confirmBox,
    required this.rejectBox,
    required this.onConfirm,
    required this.onReject,
  });

  final int index;
  final String textBn;
  final bool quiet;
  final bool armed;
  final double maxHeight;
  final GlobalKey confirmBox;
  final GlobalKey rejectBox;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SlmColors.navy700, SlmColors.navy900],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SlmColors.gold400, width: 1.6),
        boxShadow: [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SlmColors.navy950.withValues(alpha: 0.7),
                    border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.9)),
                  ),
                  child: Text(enDigits('${index + 1}'), style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('choice-preview-scroll'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        enDigits(textBn),
                        key: const ValueKey('choice-preview-text'),
                        style: bangla(fontSize: 18.5, fontWeight: FontWeight.w800, height: 1.42, color: SlmColors.ivory),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // No tap while it opens: a quick second tap on the card can't confirm.
          IgnorePointer(
            ignoring: !armed,
            child: AnimatedOpacity(
              opacity: armed ? 1 : 0.55,
              duration: quiet ? Duration.zero : const Duration(milliseconds: 160),
              child: Row(
                children: [
                  Expanded(
                    child: _PreviewButton(
                      boxKey: rejectBox,
                      tapKey: const ValueKey('choice-reject'),
                      icon: Icons.close_rounded,
                      label: ChoiceDeckLines.reject,
                      filled: false,
                      onTap: onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PreviewButton(
                      boxKey: confirmBox,
                      tapKey: const ValueKey('choice-confirm'),
                      icon: Icons.check_rounded,
                      label: ChoiceDeckLines.confirm,
                      filled: true,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final centred = Center(heightFactor: 1, child: card);
    if (quiet) return centred;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.9 + 0.1 * t, alignment: Alignment.bottomCenter, child: child),
      ),
      child: centred,
    );
  }
}

/// ✕ বাদ দিন (outlined) or ✓ বেছে নিন (gold) — at least 52 dp tall.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.boxKey,
    required this.tapKey,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final GlobalKey boxKey;
  final Key tapKey;
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? SlmColors.navy950 : SlmColors.ivory;
    return KeyedSubtree(
      key: boxKey,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: filled ? SlmColors.gold400 : SlmColors.navy950.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: filled ? SlmColors.gold200 : SlmColors.gold400.withValues(alpha: 0.75), width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: tapKey,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: fg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: fg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One card: slides in (staggered, with a card sound), lands with a squash,
/// presses under the finger, shakes red when wrong, pops green when right;
/// set aside (✕ on its preview) it is dimmed, grey and struck — still open.
class _DealtCard extends StatefulWidget {
  const _DealtCard({
    super.key,
    required this.boxKey,
    required this.index,
    required this.option,
    required this.quiet,
    required this.muted,
    required this.wrong,
    required this.right,
    required this.aside,
    required this.onOpen,
  });

  /// Where the card is on screen (the deck's sweep hint).
  final GlobalKey boxKey;
  final int index;
  final ChoiceOption option;
  final bool quiet;
  final bool muted;
  final bool wrong;
  final bool right;

  /// Set aside by the player (✕): dimmed and struck, not red; still opens.
  final bool aside;

  /// A tap opens the card's preview (never an answer by itself).
  final void Function(ChoiceOption option, Offset origin) onOpen;

  @override
  State<_DealtCard> createState() => _DealtCardState();
}

class _DealtCardState extends State<_DealtCard> with TickerProviderStateMixin {
  static const _landAt = 0.74;
  late final AnimationController _deal = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _hit = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  Timer? _delay;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _deal.value = 1;
      return;
    }
    _delay = Timer(Duration(milliseconds: 90 + widget.index * 130), () {
      if (!mounted) return;
      if (!widget.muted) {
        final file = widget.index.isEven ? 'sounds/learn/card_deal_a.wav' : 'sounds/learn/card_deal_b.wav';
        unawaited(ZlFx.cue(file, volume: 0.62, muted: false));
      }
      unawaited(_deal.forward());
    });
  }

  @override
  void didUpdateWidget(_DealtCard old) {
    super.didUpdateWidget(old);
    final hit = (widget.wrong && !old.wrong) || (widget.right && !old.right);
    if (hit && !widget.quiet) unawaited(_hit.forward(from: 0));
  }

  @override
  void dispose() {
    _delay?.cancel();
    _deal.dispose();
    _hit.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    final hot = widget.wrong || widget.right;
    final good = widget.right;
    final locked = widget.wrong || widget.right;
    final aside = widget.aside && !hot;
    final face = AnimatedContainer(
      duration: widget.quiet ? Duration.zero : SlmMotion.fast,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hot
              ? (good
                  ? [SlmColors.emerald500.withValues(alpha: 0.34), SlmColors.navy800]
                  : [SlmColors.danger.withValues(alpha: 0.34), SlmColors.navy800])
              : aside
                  ? [SlmColors.navy900, SlmColors.navy950]
                  : [SlmColors.navy800, SlmColors.navy900],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hot
              ? (good ? SlmColors.emerald400 : SlmColors.danger)
              : aside
                  ? SlmColors.slate.withValues(alpha: 0.45)
                  : SlmColors.gold400.withValues(alpha: 0.5),
          width: hot ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: SlmColors.gold400.withValues(alpha: hot ? 0.26 : (aside ? 0.0 : 0.12)),
            blurRadius: hot ? 20 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SlmColors.navy950.withValues(alpha: 0.7),
              border: Border.all(
                color: (hot ? (good ? SlmColors.emerald400 : SlmColors.danger) : (aside ? SlmColors.slate : SlmColors.gold300)).withValues(alpha: 0.8),
              ),
            ),
            child: hot
                ? Icon(good ? Icons.check_rounded : Icons.close_rounded, size: 18, color: good ? SlmColors.emerald400 : SlmColors.danger)
                : aside
                ? const Icon(Icons.remove_rounded, key: ValueKey('choice-aside-mark'), size: 18, color: SlmColors.slate)
                : Text(enDigits('${widget.index + 1}'), style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: widget.wrong ? 0.6 : (aside ? 0.55 : 1),
              child: Text(
                enDigits(o.textBn),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bangla(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3, color: aside ? SlmColors.mist : SlmColors.ivory).copyWith(
                  decoration: aside ? TextDecoration.lineThrough : null,
                  decorationColor: SlmColors.slate,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final card = Semantics(
      key: widget.boxKey,
      button: true,
      label: o.textBn,
      value: aside ? ChoiceDeckLines.asideTag : null,
      child: Listener(
        onPointerDown: locked ? null : (_) => _press(true),
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: locked
              ? null
              : (d) => widget.onOpen(o, d.globalPosition),
          child: AnimatedScale(scale: _pressed ? 0.95 : 1, duration: const Duration(milliseconds: 90), curve: Curves.easeOut, child: face),
        ),
      ),
    );
    if (widget.quiet) return card;
    final width = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: Listenable.merge([_deal, _hit]),
      child: card,
      builder: (_, child) {
        final t = _deal.value;
        final travel = Curves.easeOutCubic.transform((t / _landAt).clamp(0.0, 1.0));
        final rest = 1 - travel;
        final land = t < _landAt ? 0.0 : (t - _landAt) / (1 - _landAt);
        final squash = math.sin(land * math.pi) * 0.06;
        var dx = rest * width * 0.85;
        var dy = rest * 18;
        var angle = rest * 0.14;
        var scale = 0.92 + 0.08 * travel;
        final h = _hit.value;
        if (h > 0 && h < 1) {
          if (widget.right) {
            scale *= 1 + 0.08 * math.sin(h * math.pi);
            dy -= 7 * math.sin(h * math.pi);
          } else {
            final fade = 1 - h;
            dx += math.sin(h * math.pi * 7) * 11 * fade;
            angle += math.sin(h * math.pi * 7) * 0.035 * fade;
          }
        }
        return Opacity(
          opacity: (t * 4).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(scale * (1 + squash), scale * (1 - squash), 1),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
