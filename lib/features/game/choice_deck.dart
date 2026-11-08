import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_fx.dart';

// Answer cards in level 1's style, for any level: a dark sheet rises from the
// bottom and the cards slide in from the right one after another (card
// sounds), each numbered; a card presses down under the finger; a wrong one
// shakes and turns red, the right one pops green. One-shot motion only —
// nothing loops while the player thinks.

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

/// The sheet with the dealt cards. [wrong]: options already tried and wrong
/// (red, shaken, no longer tappable); [picked]: the right one, once chosen.
class ChoiceDeck extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _DealtCard(
                key: ValueKey('deal-${options[i].textBn}'),
                index: i,
                option: options[i],
                quiet: quiet,
                muted: muted,
                wrong: wrong.contains(options[i].textBn),
                right: picked == options[i].textBn,
                onPick: onPick,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One card: slides in (staggered, with a card sound), lands with a squash,
/// presses under the finger, shakes red when wrong, pops green when right.
class _DealtCard extends StatefulWidget {
  const _DealtCard({
    super.key,
    required this.index,
    required this.option,
    required this.quiet,
    required this.muted,
    required this.wrong,
    required this.right,
    required this.onPick,
  });

  final int index;
  final ChoiceOption option;
  final bool quiet;
  final bool muted;
  final bool wrong;
  final bool right;
  final void Function(ChoiceOption option, Offset origin) onPick;

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
              : [SlmColors.navy800, SlmColors.navy900],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hot ? (good ? SlmColors.emerald400 : SlmColors.danger) : SlmColors.gold400.withValues(alpha: 0.5),
          width: hot ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(color: SlmColors.gold400.withValues(alpha: hot ? 0.26 : 0.12), blurRadius: hot ? 20 : 12, offset: const Offset(0, 5)),
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
              border: Border.all(color: (hot ? (good ? SlmColors.emerald400 : SlmColors.danger) : SlmColors.gold300).withValues(alpha: 0.8)),
            ),
            child: hot
                ? Icon(good ? Icons.check_rounded : Icons.close_rounded, size: 18, color: good ? SlmColors.emerald400 : SlmColors.danger)
                : Text(enDigits('${widget.index + 1}'), style: bangla(fontSize: 14.5, fontWeight: FontWeight.w900, color: SlmColors.gold200)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: widget.wrong ? 0.6 : 1,
              child: Text(
                enDigits(o.textBn),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bangla(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3, color: SlmColors.ivory),
              ),
            ),
          ),
        ],
      ),
    );
    final card = Semantics(
      button: true,
      label: o.textBn,
      child: Listener(
        onPointerDown: locked ? null : (_) => _press(true),
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: locked
              ? null
              : (d) {
                  if (!widget.muted) unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.55, muted: false));
                  widget.onPick(o, d.globalPosition);
                },
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
