import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../radio/radio_player_provider.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'profile_edit.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final guest = auth.isGuest || !auth.isAuthenticated;
    final verified = linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final name = guest ? tr(bn, 'অতিথি', 'Guest') : (profile?.displayName ?? tr(bn, 'লাইনম্যান', 'Lineman'));
    final mail = auth.email?.trim() ?? '';
    final district = profile?.district?.trim() ?? '';
    final blockReady = district.isNotEmpty;

    final tools = <_Row>[
      _Row(tr(bn, 'জরুরি', 'Emergency'), Icons.warning_rounded, SlmColors.danger, () {
        Navigator.of(context).pushNamed(AppRoutes.emergency);
      }),
      _Row(tr(bn, 'আমার পিপিই', 'My PPE'), Icons.health_and_safety_rounded, SlmColors.emerald300, () {
        Navigator.of(context).pushNamed(AppRoutes.ppe);
      }),
      _Row(tr(bn, 'রেডিও', 'Radio'), Icons.radio_rounded, SlmColors.gold300, () {
        ref.read(radioProvider.notifier).showPlayer();
        ref.read(radioProvider.notifier).togglePlay();
      }),
      if (auth.isAdmin)
        _Row(tr(bn, 'অ্যাডমিন', 'Admin'), Icons.admin_panel_settings_rounded, SlmColors.gold400, () {
          Navigator.of(context).pushNamed(AppRoutes.admin);
        }),
      if (kDebugMode)
        _Row(tr(bn, 'প্রিমিয়াম প্রিভিউ', 'Premium preview'), Icons.auto_awesome_rounded, SlmColors.gold400, () {
          Navigator.of(context).pushNamed(AppRoutes.premiumPreview);
        }),
      if (kDebugMode)
        _Row(tr(bn, 'মোশন শোকেস', 'Motion showcase'), Icons.animation_rounded, SlmColors.emerald300, () {
          Navigator.of(context).pushNamed(AppRoutes.motionShowcase);
        }),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Builder(builder: (context) {
          final g = context.slm.layout.gutter;
          return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
              ShellSafeArea(
                child: ListView(
                  padding: shellScrollPadding(context, left: g, top: 4, right: g, extraBottom: 12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: SlmColors.ivory),
                        tooltip: tr(bn, 'ফিরে যান', 'Back'),
                      ),
                    ),
                    const SizedBox(height: SlmSpace.xs),
                    Row(
                      children: [
                        Flexible(
                          child: SlmText(name, role: SlmTextRole.headline, color: SlmColors.ivory, maxLines: 1),
                        ),
                        const SizedBox(width: SlmSpace.xs),
                        GestureDetector(
                          onTap: verified ? null : () => showVerifySheet(context),
                          child: VerifyTick(gold: verified, size: 26),
                        ),
                      ],
                    ),
                    if (!guest && mail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SlmText(mail, role: SlmTextRole.caption, color: SlmColors.gold300, maxLines: 1),
                    ],
                    if (!guest) ...[
                      const SizedBox(height: SlmSpace.xl),
                      SlmSectionHeader(title: tr(bn, 'আমার পরিচয়', 'My details')),
                      _Card(
                        children: [
                          _ValueRow(
                            label: tr(bn, 'নাম', 'Name'),
                            value: _shown(profile?.fullName),
                            onTap: () => showNameSheet(context, ref),
                          ),
                          _ValueRow(
                            label: tr(bn, 'জেলা', 'District'),
                            value: _shown(profile?.district),
                            onTap: () => showDistrictSheet(context, ref),
                          ),
                          _ValueRow(
                            label: tr(bn, 'ব্লক', 'Block'),
                            value: blockReady ? _shown(profile?.block) : tr(bn, 'আগে জেলা', 'District first'),
                            enabled: blockReady,
                            onTap: () => showBlockSheet(context, ref),
                          ),
                          _ValueRow(
                            label: tr(bn, 'কাজ', 'Job'),
                            value: _shown(profile?.job),
                            onTap: () => showJobSheet(context, ref),
                          ),
                          _ValueRow(
                            label: tr(bn, 'ফোন', 'Phone'),
                            value: _shown(profile?.phone),
                            onTap: () => showPhoneSheet(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: SlmSpace.lg),
                      SlmSectionHeader(title: tr(bn, 'আমার কাগজ', 'My papers')),
                      _Card(
                        children: [
                          _AccountRow(
                            row: _Row(
                              tr(bn, 'সার্টিফিকেট', 'Certificate'),
                              Icons.workspace_premium_rounded,
                              SlmColors.gold300,
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const CertificatePage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!guest) ...[
                      const SizedBox(height: SlmSpace.lg),
                      SlmSectionHeader(title: tr(bn, 'সরঞ্জাম', 'Tools')),
                      _Card(children: [for (final tool in tools) _AccountRow(row: tool)]),
                    ],
                    const SizedBox(height: SlmSpace.xl),
                    if (auth.isAuthenticated)
                      SlmButton(
                        label: tr(bn, 'লগআউট', 'Log out'),
                        icon: Icons.logout_rounded,
                        variant: SlmButtonVariant.danger,
                        size: SlmButtonSize.large,
                        expand: true,
                        onPressed: () => _confirmSignOut(context, ref, bn),
                      )
                    else
                      SlmButton.gold(
                        label: tr(bn, 'লগইন', 'Log in'),
                        icon: Icons.login_rounded,
                        size: SlmButtonSize.large,
                        expand: true,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        }),
      ),
    );
  }

  String _shown(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }
}

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref, bool bn) async {
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

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return SlmCard(
      variant: SlmCardVariant.surface,
      padding: EdgeInsets.zero,
      radius: SlmRadius.md,
      child: Column(children: _withDividers(children)),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(Divider(height: 1, color: SlmColors.gold400.withValues(alpha: 0.18)));
      }
      out.add(items[i]);
    }
    return out;
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  const _ValueRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ink = enabled ? SlmColors.ivory : SlmColors.slate;
    return SlmPressable(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: SlmText(label, role: SlmTextRole.titleSm, color: ink, maxLines: 1)),
            const SizedBox(width: 12),
            Flexible(
              child: SlmText(value, role: SlmTextRole.bodySm, color: SlmColors.mist, maxLines: 1, align: TextAlign.right),
            ),
            Icon(Icons.chevron_right_rounded, color: enabled ? SlmColors.gold300 : SlmColors.slate),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final String label;
  final IconData icon;
  final Color ink;
  final VoidCallback onTap;

  const _Row(this.label, this.icon, this.ink, this.onTap);
}

class _AccountRow extends StatelessWidget {
  final _Row row;

  const _AccountRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: row.ink.withValues(alpha: 0.14),
                border: Border.all(color: row.ink.withValues(alpha: 0.45)),
              ),
              child: Icon(row.icon, color: row.ink, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: SlmText(row.label, role: SlmTextRole.titleSm, color: SlmColors.ivory, maxLines: 1)),
            const Icon(Icons.chevron_right_rounded, color: SlmColors.gold300),
          ],
        ),
      ),
    );
  }
}
