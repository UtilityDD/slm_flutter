import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/slm_design.dart';
import '../shell/shell_providers.dart';
import 'auth_provider.dart';

Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final bn = ref.read(languageProvider);
  final go = await showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'logout',
    barrierColor: SlmColors.navy950.withValues(alpha: 0.88),
    transitionDuration: SlmMotion.slow,
    transitionBuilder: (_, anim, _, child) {
      final t = SlmMotion.emphasized.transform(anim.value);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      );
    },
    pageBuilder: (ctx, _, _) {
      return Center(
        child: Theme(
          data: SlmTheme.night(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment(0, -1.1),
                      radius: 1.3,
                      colors: [SlmColors.navy700, SlmColors.navy900, SlmColors.navy950],
                      stops: [0, 0.5, 1],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 28, offset: const Offset(0, 12))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SlmIconBadge(icon: Icons.logout_rounded, style: SlmIconStyle.medal, size: 52),
                        const SizedBox(height: SlmSpace.md),
                        SlmText(
                          tr(bn, 'লগআউট করবেন?', 'Log out?'),
                          role: SlmTextRole.title,
                          color: SlmColors.ivory,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: SlmSpace.xs),
                        SlmText(
                          tr(bn, 'এই ফোন থেকে অ্যাকাউন্ট বন্ধ হবে। আবার ঢুকতে লগইন লাগবে।', 'This signs you out on this phone. You will need to log in again.'),
                          role: SlmTextRole.bodySm,
                          color: SlmColors.mist,
                          align: TextAlign.center,
                          maxLines: 3,
                        ),
                        const SizedBox(height: SlmSpace.lg),
                        SlmButton(
                          label: tr(bn, 'লগআউট', 'Log out'),
                          variant: SlmButtonVariant.danger,
                          expand: true,
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                        const SizedBox(height: SlmSpace.xs),
                        SlmButton.ghost(
                          label: tr(bn, 'থাক', 'Stay'),
                          expand: true,
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  if (go == true) await ref.read(authProvider.notifier).signOut();
}
