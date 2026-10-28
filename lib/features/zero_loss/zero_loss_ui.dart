import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../home/bangla_read_aloud.dart';
import 'zero_loss_engine.dart';
import 'zero_loss_models.dart';

/// Night-shift palette shared by every জিরো লস screen.
class ZlColors {
  static const bg = Color(0xFF0B1220);
  static const panel = Color(0xFF131C2E);
  static const panelHi = Color(0xFF1B2740);
  static const line = Color(0xFF26334D);
  static const text = Color(0xFFF1F5F9);
  static const soft = Color(0xFF94A3B8);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF38BDF8);
  static const orange = Color(0xFFFB923C);
  static const cream = Color(0xFFFFF5EE);
}

/// On-screen numbers stay in English digits.
String n(Object v) {
  if (v is num) return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return enDigits('$v');
}

String pct(double v) => '${n((v * 100).round())}%';

TextStyle zlText(double size, {FontWeight weight = FontWeight.w500, Color color = ZlColors.text, double? height}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFamilyFallback: const ['Roboto', 'Noto Sans'],
      fontFeatures: const [FontFeature.localeAware(enable: false)],
    );

Color severityColor(String severity) => switch (severity) {
      'critical' => ZlColors.red,
      'high' => ZlColors.orange,
      _ => ZlColors.amber,
    };

Color outcomeColor(MissionOutcome? o) => switch (o) {
      MissionOutcome.safe => ZlColors.green,
      MissionOutcome.lucky => ZlColors.amber,
      MissionOutcome.accident => ZlColors.red,
      null => ZlColors.soft,
    };

IconData mantraIcon(String id) => switch (id) {
      'stop' => Icons.front_hand_rounded,
      'armour' => Icons.health_and_safety_rounded,
      'permit' => Icons.assignment_turned_in_rounded,
      'cut' => Icons.power_off_rounded,
      'earth' => Icons.electrical_services_rounded,
      'fence' => Icons.fence_rounded,
      'mend' => Icons.handyman_rounded,
      'count' => Icons.fact_check_rounded,
      _ => Icons.shield_rounded,
    };

Color mantraColor(String id) => switch (id) {
      'stop' => const Color(0xFFEF4444),
      'armour' => const Color(0xFFFB923C),
      'permit' => const Color(0xFF38BDF8),
      'cut' => const Color(0xFFA78BFA),
      'earth' => const Color(0xFFF59E0B),
      'fence' => const Color(0xFFF472B6),
      'mend' => const Color(0xFF2DD4BF),
      'count' => const Color(0xFF22C55E),
      _ => ZlColors.soft,
    };

IconData optionIcon(String key) => switch (key) {
      'wait' => Icons.hourglass_top_rounded,
      'climb' => Icons.stairs_rounded,
      'alone' => Icons.person_off_rounded,
      'permit' => Icons.assignment_turned_in_rounded,
      'phone' => Icons.phone_in_talk_rounded,
      'switch' => Icons.toggle_off_rounded,
      'earth' => Icons.electrical_services_rounded,
      'earth_one' => Icons.looks_one_rounded,
      'no_earth' => Icons.block_rounded,
      'count' => Icons.fact_check_rounded,
      'power_on' => Icons.power_rounded,
      'earth_off' => Icons.link_off_rounded,
      'fence' => Icons.fence_rounded,
      'shout' => Icons.campaign_rounded,
      'bamboo' => Icons.dangerous_rounded,
      'ppe' => Icons.health_and_safety_rounded,
      'skip' => Icons.do_not_disturb_on_rounded,
      'rush' => Icons.flash_on_rounded,
      'open' => Icons.lock_open_rounded,
      'armour' => Icons.shield_rounded,
      'mend' => Icons.handyman_rounded,
      'waist_belt' => Icons.do_not_step_rounded,
      'plain_pliers' => Icons.build_circle_rounded,
      'plain_wire' => Icons.cable_rounded,
      'wet_cloth' => Icons.water_drop_rounded,
      _ => Icons.chevron_right_rounded,
    };

IconData _gearIcon(String key) => switch (key) {
      'permit' => Icons.assignment_rounded,
      _ => Icons.build_rounded,
    };

String speakerName(ZeroLossState s, String faultId, HazardEvent e) => switch (e.speaker) {
      'lead' => s.leadOf(faultId)?.name ?? 'টিম লিডার',
      'junior' => s.juniorOf(faultId)?.name ?? 'হেল্পার',
      'substation' => 'সাবস্টেশন',
      'helper' => 'হেল্পার',
      'public' => 'হাটের লোক',
      _ => '',
    };

SmartLineman? speakerMan(ZeroLossState s, String faultId, HazardEvent e) => switch (e.speaker) {
      'lead' => s.leadOf(faultId),
      'junior' => s.juniorOf(faultId),
      _ => null,
    };

IconData speakerIcon(String speaker) => switch (speaker) {
      'substation' => Icons.cell_tower_rounded,
      'public' => Icons.groups_rounded,
      _ => Icons.person_rounded,
    };

// ---------------------------------------------------------------------------
// Voice
// ---------------------------------------------------------------------------

class ZlVoice {
  final _tts = BanglaReadAloud();
  final mutedNotifier = ValueNotifier(false);

  bool get muted => mutedNotifier.value;
  set muted(bool v) => mutedNotifier.value = v;

  /// [rate] is only for a short line. Game talk stays at the slower default.
  /// [onClause] fires as each punctuation-separated piece starts.
  void say(String text, {double rate = 0.42, void Function(int index)? onClause}) {
    if (muted || text.trim().isEmpty) return;
    _tts.speak(text, rate: rate, onClause: onClause);
  }

  /// Waits until this line has been spoken. A muted player still pauses to read.
  Future<void> sayAwait(String text, {double rate = 0.42}) async {
    if (text.trim().isEmpty) return;
    if (muted) {
      await Future<void>.delayed(Duration(milliseconds: 700 + text.length * 45));
      return;
    }
    await _tts.speakAwait(text, rate: rate);
  }

  void stop() => _tts.stop();
}

final zlVoiceProvider = Provider.autoDispose<ZlVoice>((ref) {
  final v = ZlVoice();
  ref.onDispose(v.stop);
  return v;
});

// ---------------------------------------------------------------------------
// Characters
// ---------------------------------------------------------------------------

const _greyscale = ColorFilter.matrix([
  0.33, 0.33, 0.33, 0, 0, //
  0.33, 0.33, 0.33, 0, 0,
  0.33, 0.33, 0.33, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Round face crop of a crew member's portrait.
class CrewFace extends StatelessWidget {
  final SmartLineman man;
  final double size;
  final Color? ring;

  const CrewFace({super.key, required this.man, this.size = 44, this.ring});

  @override
  Widget build(BuildContext context) {
    final w = size * 3.2;
    final h = w * 4 / 3;
    Widget face = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: ZlColors.cream,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: size / 2 - w * 0.49,
                top: size / 2 - h * 0.14,
                width: w,
                height: h,
                child: Image.asset(
                  man.art,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => Center(child: Text(man.name.characters.first)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (man.isInjured) face = ColorFiltered(colorFilter: _greyscale, child: face);
    return Container(
      padding: EdgeInsets.all(ring == null ? 0 : 2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: face,
    );
  }
}

/// Full-body portrait, backdrop already removed.
class CrewFigure extends StatelessWidget {
  final SmartLineman man;

  const CrewFigure({super.key, required this.man});

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      man.art,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, _, _) => const Icon(Icons.person_rounded, size: 64),
    );
    if (man.isInjured) img = ColorFiltered(colorFilter: _greyscale, child: img);
    return img;
  }
}

/// Charge left in the body, sitting at the hip. No chip behind it.
class EnergyBadge extends StatelessWidget {
  final SmartLineman man;
  final int tiredThreshold;

  const EnergyBadge({super.key, required this.man, required this.tiredThreshold});

  @override
  Widget build(BuildContext context) {
    final f = man.fatigueLevel;
    final color = f >= tiredThreshold ? ZlColors.red : f >= 40 ? ZlColors.amber : ZlColors.green;
    final icon = f >= 75
        ? Icons.battery_1_bar_rounded
        : f >= tiredThreshold
            ? Icons.battery_2_bar_rounded
            : f >= 40
                ? Icons.battery_4_bar_rounded
                : Icons.battery_full_rounded;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(angle: pi / 2, child: Icon(icon, size: 18, color: color)),
        Text(n(100 - f), style: zlText(11, weight: FontWeight.w900, color: color, height: 1)),
      ],
    );
  }
}

/// Five pips along the side of the body. Filled pips are how careful he is.
class SafetyShield extends StatelessWidget {
  final int rating;

  const SafetyShield({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final c = rating >= 4 ? ZlColors.green : rating == 3 ? ZlColors.amber : ZlColors.red;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 5; i >= 1; i--)
          Container(
            width: 7,
            height: 9,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: i <= rating ? c : c.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gear
// ---------------------------------------------------------------------------

/// A name that fades in, rests, and fades away. No box behind it.
class GentleName extends StatelessWidget {
  final String text;
  final bool show;
  final double size;

  const GentleName({super.key, required this.text, required this.show, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, 0.4),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: zlText(size, weight: FontWeight.w700).copyWith(
            shadows: const [Shadow(color: Color(0xE60B1220), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

/// Gear art on a spotlight tile; falls back to an icon tile when the item has no picture.
class GearPicture extends StatelessWidget {
  final Gear gear;
  final double size;

  /// No dark tile. The picture sits on its own.
  final bool plain;

  const GearPicture({super.key, required this.gear, this.size = 56, this.plain = false});

  static const _spot = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 0.85,
    colors: [Color(0xFF3B4766), Color(0xFF1A2133)],
  );

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFDE68A)]),
      ),
      child: Center(
        child: gear.icon.isNotEmpty
            ? Icon(_gearIcon(gear.icon), size: size * 0.5, color: const Color(0xFF9A3412))
            : Text(gear.emoji.isEmpty ? '🔧' : gear.emoji, style: TextStyle(fontSize: size * 0.45)),
      ),
    );
    if (plain && gear.image.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(gear.image, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: gear.image.isEmpty
            ? fallback
            : DecoratedBox(
                decoration: const BoxDecoration(gradient: _spot),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.08),
                  child: Image.asset(gear.image, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mantras
// ---------------------------------------------------------------------------

class MantraBadge extends StatelessWidget {
  final SafetyMantra mantra;
  final double size;
  final bool? ok;
  final bool active;

  const MantraBadge({super.key, required this.mantra, this.size = 30, this.ok, this.active = false});

  @override
  Widget build(BuildContext context) {
    final c = mantraColor(mantra.id);
    final bg = ok == null ? (active ? c : ZlColors.panelHi) : (ok! ? ZlColors.green : ZlColors.red);
    return AnimatedScale(
      scale: active ? 1.18 : 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: active ? Colors.white : c.withValues(alpha: 0.6), width: active ? 2 : 1),
          boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 10)] : null,
        ),
        child: Icon(
          ok == null ? mantraIcon(mantra.id) : (ok! ? Icons.check_rounded : Icons.close_rounded),
          size: size * 0.55,
          color: ok == null && !active ? c : Colors.white,
        ),
      ),
    );
  }
}

/// The eight mantras in order, lit by progress.
class MantraRail extends StatelessWidget {
  final ZeroLossScenario scenario;
  final Map<String, bool> report;
  final String? activeId;

  /// Smaller badges and no caption.
  final bool compact;

  const MantraRail({super.key, required this.scenario, required this.report, this.activeId, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final active = activeId == null ? null : scenario.mantra(activeId!);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final m in scenario.mantras)
              MantraBadge(
                mantra: m,
                size: compact ? 24 : 30,
                ok: m.id == activeId ? null : report[m.id],
                active: m.id == activeId,
              ),
          ],
        ),
        if (active != null && !compact) ...[
          const SizedBox(height: 6),
          Text(
            '${active.nameBn} · ${active.chantBn}',
            style: zlText(12, weight: FontWeight.w700, color: mantraColor(active.id)),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Effects
// ---------------------------------------------------------------------------

/// Falling rain with an occasional lightning flash.
class StormOverlay extends StatefulWidget {
  final int drops;
  final bool lightning;

  const StormOverlay({super.key, this.drops = 70, this.lightning = true});

  @override
  State<StormOverlay> createState() => _StormOverlayState();
}

class _StormOverlayState extends State<StormOverlay> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final _seeds = List.generate(widget.drops, (i) {
    final r = Random(i * 7919);
    return (r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 0.8);
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _StormPainter(t: _c.value, seeds: _seeds, lightning: widget.lightning),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _StormPainter extends CustomPainter {
  final double t;
  final List<(double, double, double)> seeds;
  final bool lightning;

  _StormPainter({required this.t, required this.seeds, required this.lightning});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x5594A3B8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final (x, y, speed) in seeds) {
      final dy = (y + t * 6 * speed) % 1.0;
      final start = Offset(x * size.width + dy * 12, dy * size.height);
      canvas.drawLine(start, start + const Offset(-4, 12), p);
    }
    if (lightning && ((t > 0.70 && t < 0.715) || (t > 0.73 && t < 0.74))) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(_StormPainter old) => old.t != t;
}

/// Shakes its child each time [trigger] changes.
class Shake extends StatelessWidget {
  final int trigger;
  final Widget child;

  const Shake({super.key, required this.trigger, required this.child});

  @override
  Widget build(BuildContext context) {
    if (trigger == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (_, v, c) => Transform.translate(offset: Offset(sin(v * pi * 6) * 9 * (1 - v), 0), child: c),
      child: child,
    );
  }
}

/// Pops in with a bounce when first built.
class PopIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final total = const Duration(milliseconds: 450) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (_, v, c) {
        final local = start >= 1 ? 1.0 : ((v - start) / (1 - start)).clamp(0.0, 1.0);
        return Transform.scale(scale: Curves.elasticOut.transform(local) * 0.999 + 0.001, child: c);
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Basic building blocks
// ---------------------------------------------------------------------------

class ZlButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final bool outlined;

  const ZlButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = ZlColors.amber,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = outlined ? color : const Color(0xFF111827);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: outlined ? Colors.transparent : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: outlined ? BorderSide(color: color, width: 1.4) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
                Flexible(
                  child: Text(label, textAlign: TextAlign.center, style: zlText(15, weight: FontWeight.w800, color: fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Points, public satisfaction, safety score and budget tokens.
class ZlStatusBar extends StatelessWidget {
  final ZeroLossState state;

  const ZlStatusBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pts = state.points;
    final ptsColor = pts < 0 ? ZlColors.red : ZlColors.amber;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          if (state.duty) ...[
            const ZlTag(label: 'ডিউটি', color: ZlColors.amber, icon: Icons.engineering_rounded),
            const SizedBox(width: 8),
          ],
          Text(
            pts > 0 ? '+${n(pts)}' : n(pts),
            style: zlText(20, weight: FontWeight.w900, color: ptsColor, height: 1),
          ),
          const SizedBox(width: 10),
          Expanded(child: _Meter(icon: Icons.sentiment_satisfied_alt_rounded, value: state.satisfaction, color: ZlColors.blue)),
          const SizedBox(width: 10),
          Expanded(child: _Meter(icon: Icons.health_and_safety_rounded, value: state.safety, color: ZlColors.green)),
          const SizedBox(width: 10),
          _Stat(icon: Icons.toll_rounded, color: ZlColors.soft, value: state.tokens),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;

  const _Stat({required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 2),
        TweenAnimationBuilder<double>(
          tween: Tween(end: value.toDouble()),
          duration: const Duration(milliseconds: 900),
          builder: (_, v, _) {
            final moving = (v - value).abs() >= 0.5;
            return AnimatedScale(
              scale: moving ? 1.25 : 1,
              duration: const Duration(milliseconds: 150),
              child: Text(
                n(v.round()),
                style: zlText(14, weight: FontWeight.w900, color: !moving ? ZlColors.text : (v > value ? ZlColors.red : ZlColors.green)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Meter extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _Meter({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = value < 30 ? ZlColors.red : color;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value / 100),
              duration: const Duration(milliseconds: 500),
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 7,
                backgroundColor: ZlColors.line,
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ZlPanel extends StatelessWidget {
  final Widget child;
  final Color? border;
  final EdgeInsetsGeometry padding;
  final Color color;

  const ZlPanel({
    super.key,
    required this.child,
    this.border,
    this.padding = const EdgeInsets.all(14),
    this.color = ZlColors.panel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? ZlColors.line, width: border == null ? 1 : 1.6),
      ),
      child: child,
    );
  }
}

class ZlTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ZlTag({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: zlText(11.5, weight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Small icon + value pair used instead of sentences.
class IconStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const IconStat({super.key, required this.icon, required this.text, this.color = ZlColors.soft});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(text, style: zlText(12, weight: FontWeight.w700, color: color)),
      ],
    );
  }
}
