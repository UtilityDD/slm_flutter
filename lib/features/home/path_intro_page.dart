import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../shell/shell_providers.dart';
import 'home_toolbox.dart';
import 'path_fear_page.dart';

/// One quiet door into মৃত্যুহীন পথ. The shield arrives from home, then a
/// gold button opens the red fear beat. Level briefings stay inside a level.
class PathIntroPage extends ConsumerWidget {
  final bool reduceMotion;

  const PathIntroPage({super.key, this.reduceMotion = false});

  void _openFear(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      SlmPageRoute<void>(
        builder: (_) => const PathFearPage(),
        style: SlmTransition.fadeThrough,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final width = MediaQuery.sizeOf(context).shortestSide;
    return Theme(
      data: SlmTheme.night(),
      child: Builder(
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SlmBackground(
                constrain: false,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                        child: Row(
                          children: [
                            SlmIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: tr(bn, 'ফিরে যান', 'Back'),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            const Spacer(),
                            HomeToolboxButton(onTap: () => openHomeToolbox(context)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AnimatedSafetyShield(
                        size: width * 0.72,
                        entrance: false,
                        heroTag: reduceMotion ? null : 'slm-home-shield',
                      ),
                      const SizedBox(height: 22),
                      SlmReveal(
                        delay: const Duration(milliseconds: 280),
                        child: const _PathTitle(),
                      ),
                      const SizedBox(height: 8),
                      SlmReveal(
                        delay: const Duration(milliseconds: 460),
                        child: SlmText(
                          tr(bn, 'সঠিক নিয়মই বাঁচার পথ।', 'The right rule is the way to stay alive.'),
                          role: SlmTextRole.body,
                          color: SlmColors.mist,
                          align: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        child: SlmButton.gold(
                          label: tr(bn, 'শুরু করা যাক', "Let's begin"),
                          trailingIcon: Icons.arrow_forward_rounded,
                          size: SlmButtonSize.large,
                          expand: true,
                          onPressed: () => _openFear(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PathTitle extends StatelessWidget {
  const _PathTitle();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: banglaFont,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: 0,
      color: SlmColors.ivory,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'মৃত্যুহীন '),
          TextSpan(text: 'পথ', style: style.copyWith(color: SlmColors.gold300)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
