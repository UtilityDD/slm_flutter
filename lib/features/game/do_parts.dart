import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../guide/ai_lineman_guide.dart';
import '../guide/guide_director.dart';
import '../guide/mascot_speech_library.dart';
import '../zero_loss/zero_loss_fx.dart';

// Pieces every Do game in the level shell shares, so all Do levels look, move
// and sound the same. Every animation plays once; an idle screen is still.

/// Someone rushing the player (a pressure moment).
@immutable
class DoCaller {
  const DoCaller({required this.id, required this.whoBn, required this.lineBn, required this.icon});
  final String id;
  final String whoBn;

  /// Spoken in the rival's (other) voice.
  final String lineBn;
  final IconData icon;
}

/// Shared button labels for a pressure moment.
abstract final class DoLines {
  static const checkFirst = 'আগে দেখুন';
  static const rushOn = 'দেখার সময় নেই';
}

/// A scene photo darkened so the play reads on top of it.
class DoBackdrop extends StatelessWidget {
  const DoBackdrop({super.key, required this.asset, this.alignment = const Alignment(-0.4, 0)});

  final String asset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final h = (MediaQuery.sizeOf(context).height * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 1200);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover, alignment: alignment, cacheHeight: h),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99050A16), Color(0x66050A16), Color(0xE6050A16)],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tap the guide and he says the task on screen again — a different way each
/// time, never the answer (level 1's "say the question again").
class TaskNudge {
  int _n = 0;

  static final List<String Function(String)> _ways = [
    (t) => t,
    (t) => 'আবার বলি — $t',
    (t) => 'তাড়াহুড়ো নয়। $t',
    (t) => 'ভালো করে দেখুন। $t',
  ];

  String next(String task) => _ways[_n++ % _ways.length](task);
}

/// The coach and his words in one strip, so he never covers the scene and
/// is never hidden behind a card. Tap him: he says the current task again
/// (the last of [tasks] he said), a different way each time.
class DoCoachStrip extends ConsumerStatefulWidget {
  const DoCoachStrip({super.key, this.tasks = const [], this.muted = false});

  /// The level's task lines (its "ask" lines).
  final List<String> tasks;
  final bool muted;

  @override
  ConsumerState<DoCoachStrip> createState() => _DoCoachStripState();
}

class _DoCoachStripState extends ConsumerState<DoCoachStrip> {
  final _nudge = TaskNudge();
  String? _task;

  void _tap() {
    final t = _task ?? (widget.tasks.isEmpty ? null : widget.tasks.first);
    if (t == null) return;
    HapticFeedback.selectionClick();
    if (!widget.muted) unawaited(ZlFx.cue('sounds/intro/tick.ogg', volume: 0.5, muted: false));
    final line = _nudge.next(t);
    ref.read(guideDirectorProvider.notifier).say(mood: GuideMood.talk, line: line);
    unawaited(MascotSpeechLibrary.speak(line, muted: widget.muted));
  }

  @override
  Widget build(BuildContext context) {
    final line = ref.watch(guideDirectorProvider.select((s) => s.line));
    if (widget.tasks.contains(line)) _task = line;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 64,
            height: 72,
            child: AiLinemanGuide(sprite: 64, bubbleWidth: 0, showBubble: false, large: false, centered: true, onTap: _tap),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: line.trim().isEmpty
                ? const SizedBox(height: 44)
                : Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0B1324),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      line,
                      style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory, height: 1.35),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Step chips (e.g. জামা → প্যান্ট → জুতো): done ones gold, the current one
/// outlined; a chip bounces once when it is done.
class DoProgress extends StatelessWidget {
  const DoProgress({super.key, required this.labels, required this.done, required this.current, required this.quiet});

  /// Round names: for screen readers only — on screen the rounds are dots.
  final List<String> labels;
  final Set<int> done;
  final int? current;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Semantics(
        label: [for (var i = 0; i < labels.length; i++) '${labels[i]}${done.contains(i) ? ' ✓' : ''}'].join(', '),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) Container(width: 14, height: 2, color: SlmColors.gold400.withValues(alpha: done.contains(i) ? 0.9 : 0.3)),
              TweenAnimationBuilder<double>(
                key: ValueKey('$i-${done.contains(i)}'),
                tween: Tween(begin: done.contains(i) && !quiet ? 1.6 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 520),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: i == current ? 14 : 11,
                  height: i == current ? 14 : 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done.contains(i) ? SlmColors.gold400 : const Color(0xCC0B1324),
                    border: Border.all(
                      color: i == current ? SlmColors.gold300 : SlmColors.gold400.withValues(alpha: 0.45),
                      width: i == current ? 2.2 : 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One tray entry: an id (stable key) and its picture.
@immutable
class DoTrayEntry {
  const DoTrayEntry({required this.id, required this.asset});
  final String id;
  final String asset;
}

/// Candidates dealt from below like Level 1's cards. Pictures only, all on
/// the same base so a tall item and a wide one weigh alike.
class DoTray extends StatelessWidget {
  const DoTray({super.key, required this.entries, required this.quiet, required this.muted, required this.onPick});

  final List<DoTrayEntry> entries;
  final bool quiet;
  final bool muted;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xF0141C2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: SlmColors.gold400.withValues(alpha: 0.4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < entries.length; i++)
            Flexible(
              key: ValueKey(entries[i].id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DoDealIn(
                  index: i,
                  quiet: quiet,
                  muted: muted,
                  child: DoTrayCard(asset: entries[i].asset, onTap: () => onPick(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One card flicked up from the deck with a spin and a bounce, then still.
class DoDealIn extends StatefulWidget {
  const DoDealIn({super.key, required this.index, required this.quiet, required this.muted, required this.child});

  final int index;
  final bool quiet;
  final bool muted;
  final Widget child;

  @override
  State<DoDealIn> createState() => _DoDealInState();
}

class _DoDealInState extends State<DoDealIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    if (widget.quiet) {
      _c.value = 1;
      return;
    }
    _delay = Timer(Duration(milliseconds: 90 * widget.index), () {
      if (!mounted) return;
      if (!widget.muted) {
        unawaited(ZlFx.cue(widget.index.isEven ? 'sounds/learn/card_deal_a.ogg' : 'sounds/learn/card_deal_b.ogg', volume: 0.55, muted: false));
      }
      _c.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = Curves.easeOutBack.transform(_c.value);
        final rest = 1 - _c.value;
        final side = widget.index.isEven ? -1.0 : 1.0;
        return Opacity(
          opacity: (_c.value * 3).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(side * 40 * rest, 180 * rest),
            child: Transform.rotate(angle: side * 0.5 * rest, child: Transform.scale(scale: 0.6 + 0.4 * t, child: child)),
          ),
        );
      },
    );
  }
}

class DoTrayCard extends StatelessWidget {
  const DoTrayCard({super.key, required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final px = (60 * MediaQuery.devicePixelRatioOf(context)).round();
    return Material(
      color: const Color(0xFF1B2A48),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 80),
          height: 88,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.45)),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // The same lit base under every item.
              Container(
                width: 52,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: RadialGradient(colors: [SlmColors.gold300.withValues(alpha: 0.35), Colors.transparent]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SizedBox(
                  width: 62,
                  height: 60,
                  child: Image(image: ResizeImage(AssetImage(asset), height: px, policy: ResizeImagePolicy.fit), fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Verdict stamp on a decided card: green when right, red otherwise.
class DoStamp extends StatelessWidget {
  const DoStamp({super.key, required this.text, required this.good});
  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final color = good ? SlmColors.emerald500 : SlmColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 3),
      ),
      child: Text(text, style: bangla(fontSize: 30, fontWeight: FontWeight.w900, color: color, height: 1.1)),
    );
  }
}

/// Three rings out of each mark (0–1 positions in the box), once.
class DoPulsePainter extends CustomPainter {
  DoPulsePainter(this.marks, this.t, {this.color = SlmColors.danger}) : super(repaint: t);
  final List<Offset> marks;
  final Animation<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0 || v >= 1) return;
    final phase = (v * 3) % 1;
    final r = size.shortestSide * (0.06 + 0.12 * phase);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: (1 - phase) * 0.9);
    for (final m in marks) {
      canvas.drawCircle(Offset(m.dx * size.width, m.dy * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(DoPulsePainter old) => old.marks != marks;
}

class DoBigButton extends StatelessWidget {
  const DoBigButton({super.key, required this.label, required this.filled, required this.onTapUp, this.onDark = false});

  final String label;
  final bool filled;
  final GestureTapUpCallback onTapUp;

  /// An outline button on the dark level page (light text and border).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? SlmColors.gold700 : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTapUp: onTapUp,
        onTap: () {},
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: onDark ? SlmColors.gold300.withValues(alpha: 0.7) : const Color(0x553A4660), width: onDark ? 1.6 : 1),
            color: !filled && onDark ? const Color(0x1AFFFFFF) : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: bangla(fontSize: 16, fontWeight: FontWeight.w900, color: filled || onDark ? Colors.white : SlmColors.ink)),
        ),
      ),
    );
  }
}

/// Someone rushing the player: the card shakes like a ringing phone, once.
class DoCallCard extends StatelessWidget {
  const DoCallCard({super.key, required this.caller, required this.quiet, required this.onAnswer, this.rushBn, this.holdBn});
  final DoCaller caller;
  final bool quiet;

  /// Button words; default "দেখার সময় নেই" / "আগে দেখুন".
  final String? rushBn;
  final String? holdBn;
  final void Function(bool heldCheck, Offset origin) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0050A16),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 700),
            builder: (_, t, child) => Transform.rotate(
              angle: math.sin(t * math.pi * 8) * 0.05 * (1 - t),
              child: Transform.scale(scale: 0.85 + 0.15 * Curves.easeOutBack.transform(t), child: child),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 26),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(color: SlmColors.ivory, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(caller.icon, color: SlmColors.danger, size: 36),
                  const SizedBox(height: 6),
                  Text(caller.whoBn, style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
                  const SizedBox(height: 8),
                  Text(
                    '“${caller.lineBn}”',
                    textAlign: TextAlign.center,
                    style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.ink, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: DoBigButton(label: rushBn ?? DoLines.rushOn, filled: false, onTapUp: (d) => onAnswer(false, d.globalPosition))),
                      const SizedBox(width: 12),
                      Expanded(child: DoBigButton(label: holdBn ?? DoLines.checkFirst, filled: true, onTapUp: (d) => onAnswer(true, d.globalPosition))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
