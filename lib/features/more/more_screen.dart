import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../../shared/widgets/slm_tiles.dart';
import '../auth/auth_provider.dart';
import '../home/home_screen.dart';
import '../radio/radio_player_provider.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);

    final items = <_MoreItem>[
      _MoreItem(tr(bn, 'আমাদের কথা', 'Our Story'), Icons.groups_rounded, TileTone.story, AppRoutes.story),
      _MoreItem(tr(bn, 'পুরস্কার', 'Prizes'), Icons.card_giftcard_rounded, TileTone.prize, AppRoutes.prizes),
      _MoreItem(tr(bn, 'আমার পিপিই', 'My PPE'), Icons.health_and_safety_rounded, TileTone.safe, AppRoutes.ppe, gapAfter: true),
      _MoreItem(tr(bn, 'অ্যাপ গাইড', 'App guide'), Icons.smartphone_rounded, TileTone.phone, AppRoutes.guide),
      _MoreItem(tr(bn, 'আমার অগ্রগতি', 'My Progress'), Icons.insights_rounded, TileTone.learn, AppRoutes.progress),
      _MoreItem(tr(bn, 'জিজ্ঞাসা', 'FAQ'), Icons.help_rounded, TileTone.folder, AppRoutes.faq),
      _MoreItem(tr(bn, 'আরো জানুন', 'Know More'), Icons.lightbulb_rounded, TileTone.idea, AppRoutes.knowMore),
      _MoreItem(tr(bn, 'ভিডিও গাইড', 'Video Guide'), Icons.smart_display_rounded, TileTone.video, AppRoutes.video),
      _MoreItem(tr(bn, 'আমার সরঞ্জাম', 'My Tools'), Icons.handyman_rounded, TileTone.tools, AppRoutes.tools),
      _MoreItem(tr(bn, 'জরুরি', 'Emergency'), Icons.warning_rounded, TileTone.sos, AppRoutes.emergency, gapBefore: true, emphasize: true),
      _MoreItem(tr(bn, 'করুণ কাহিনী', 'Tragic Stories'), Icons.favorite_rounded, TileTone.heart, AppRoutes.tales),
      _MoreItem(tr(bn, 'SLM রেডিও', 'SLM Radio'), Icons.radio_rounded, TileTone.indigo, null, action: _MoreAction.radio),
      _MoreItem(tr(bn, 'বিজ্ঞপ্তি', 'Notifications'), Icons.notifications_rounded, TileTone.bell, AppRoutes.notices),
      _MoreItem(tr(bn, 'প্রশ্নোত্তর', 'Forum'), Icons.forum_rounded, TileTone.forum, AppRoutes.forum),
      _MoreItem(tr(bn, 'শেয়ার করুন', 'Share'), Icons.share_rounded, TileTone.share, null, action: _MoreAction.share),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(tr(bn, 'আরও', 'More')),
      ),
      body: SlmBackdrop(
        child: ListView(
          padding: shellScrollPadding(context, left: 16, top: 4, right: 16, extraBottom: 16),
          children: [
            for (final item in items) ...[
              if (item.gapBefore) const SizedBox(height: 10),
              More3dRow(
                label: item.label,
                icon: item.icon,
                tone: item.tone,
                emphasize: item.emphasize,
                onTap: () => _onTap(context, ref, bn, item),
              ),
              SizedBox(height: item.gapAfter ? 16 : 10),
            ],
            const SizedBox(height: 8),
            if (auth.isAuthenticated)
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, color: AppColors.alertRed),
                label: Text(tr(bn, 'লগআউট', 'Log out'), style: const TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w600)),
              )
            else
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                icon: const Icon(Icons.login_rounded),
                label: Text(tr(bn, 'লগইন', 'Log in')),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, bool bn, _MoreItem item) {
    switch (item.action) {
      case _MoreAction.radio:
        ref.read(radioProvider.notifier).showPlayer();
        ref.read(radioProvider.notifier).togglePlay();
        return;
      case _MoreAction.share:
        copyInvite(context, bn);
        return;
      case _MoreAction.none:
        break;
    }
    final route = item.route;
    if (route != null) {
      Navigator.of(context).pushNamed(route);
    }
  }
}

enum _MoreAction { none, radio, share }

class _MoreItem {
  final String label;
  final IconData icon;
  final TileTone tone;
  final String? route;
  final bool gapBefore;
  final bool gapAfter;
  final bool emphasize;
  final _MoreAction action;

  const _MoreItem(
    this.label,
    this.icon,
    this.tone,
    this.route, {
    this.gapBefore = false,
    this.gapAfter = false,
    this.emphasize = false,
    this.action = _MoreAction.none,
  });
}
