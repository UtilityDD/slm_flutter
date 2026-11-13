import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../zero_loss/zero_loss_ui.dart' show zlText;
import 'game_save.dart';

// The lucky toolbox's shield (lucky_toolbox.dart): a pending shield forgives
// the next small slip in a Do level. DoStrikeOut.strike asks
// [toolboxShieldSaves] first; when it returns true the strike is not counted
// (the level still shows the mistake card and books it, and its own mark —
// 100 − 15 per slip — is unchanged: the shield only keeps the strike-out away).

abstract final class ToolboxShieldLines {
  static const saved = 'শিল্ড বাঁচাল!';
}

const kToolboxShieldArt = 'assets/duty_slip/world3d/prop_shield.webp';

/// Uses a pending shield, if any: a brief toast, true = do not count this strike.
bool toolboxShieldSaves(WidgetRef ref, BuildContext context) {
  if (!ref.read(gameSaveProvider.notifier).useToolboxShield()) return false;
  HapticFeedback.mediumImpact();
  showToolboxShieldToast(context);
  return true;
}

/// A short code-drawn toast with the shield picture; removes itself (~1.6 s).
void showToolboxShieldToast(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => ToolboxShieldToast(onDone: () {
      if (entry.mounted) entry.remove();
    }),
  );
  overlay.insert(entry);
}

class ToolboxShieldToast extends StatefulWidget {
  const ToolboxShieldToast({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ToolboxShieldToast> createState() => _ToolboxShieldToastState();
}

class _ToolboxShieldToastState extends State<ToolboxShieldToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _c.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pill = DecoratedBox(
      key: const ValueKey('toolbox-shield-toast'),
      decoration: BoxDecoration(
        color: const Color(0xF20A1426),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SlmColors.gold300, width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x88FFD56A), blurRadius: 18)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 18, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(kToolboxShieldArt, width: 38, height: 38, cacheWidth: 120, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Text(ToolboxShieldLines.saved, style: zlText(17, weight: FontWeight.w900, color: SlmColors.gold100)),
          ],
        ),
      ),
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 72,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: still
              ? pill
              : AnimatedBuilder(
                  animation: _c,
                  child: pill,
                  builder: (context, child) {
                    final t = _c.value;
                    final inT = Curves.easeOutBack.transform((t / 0.18).clamp(0.0, 1.0));
                    final out = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: out,
                      child: Transform.scale(scale: 0.6 + 0.4 * inT, child: child),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
