import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../guide/guide_director.dart';
import 'game_save.dart';

/// Shared beat FX bus — score chips, later death/hint.
class BeatFx {
  BeatFx._();

  static Future<void> scoreDelta(
    WidgetRef ref,
    int delta, {
    String? rungId,
    GuideMood? mood,
  }) async {
    await ref.read(gameSaveProvider.notifier).addPoints(delta, rungId: rungId);
    if (mood != null) {
      ref.read(guideDirectorProvider.notifier).react(mood);
    } else if (delta > 0) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.glad);
    } else if (delta < 0) {
      ref.read(guideDirectorProvider.notifier).react(GuideMood.warn);
    }
  }
}

/// Overlay that flies the latest GameSave pulse toward the top score chip.
class ScoreFlyHost extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey scoreKey;

  const ScoreFlyHost({super.key, required this.child, required this.scoreKey});

  @override
  ConsumerState<ScoreFlyHost> createState() => _ScoreFlyHostState();
}

class _ScoreFlyHostState extends ConsumerState<ScoreFlyHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int? _seenAt;
  int _delta = 0;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tryLaunch(ScorePulse? pulse, Offset origin) {
    if (pulse == null || pulse.atMs == _seenAt) return;
    _seenAt = pulse.atMs;
    final box = widget.scoreKey.currentContext?.findRenderObject() as RenderBox?;
    final target = box?.localToGlobal(Offset(box.size.width / 2, box.size.height / 2)) ?? const Offset(48, 48);
    setState(() {
      _delta = pulse.delta;
      _from = origin;
      _to = target;
    });
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final saveCtrl = ref.read(gameSaveProvider.notifier);
    ref.listen(gameSaveProvider, (prev, next) {
      final pulse = saveCtrl.lastPulse;
      if (pulse == null) return;
      final size = MediaQuery.sizeOf(context);
      _tryLaunch(pulse, Offset(size.width * 0.5, size.height * 0.55));
    });

    final reduce = slmReduceMotion(context);
    return Stack(
      children: [
        widget.child,
        if (_delta != 0)
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = reduce ? 1.0 : Curves.easeOutCubic.transform(_c.value);
              final pos = Offset.lerp(_from, _to, t)!;
              final opacity = (1.0 - t * 0.15).clamp(0.0, 1.0);
              final label = _delta > 0 ? '+$_delta' : '$_delta';
              final color = _delta > 0 ? SlmColors.emerald300 : SlmColors.danger;
              return Positioned(
                left: pos.dx - 28,
                top: pos.dy - 14,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: 1.05 - 0.15 * t,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
