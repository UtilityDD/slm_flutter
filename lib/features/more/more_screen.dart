import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/google_mark.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
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
    final initial = name.isEmpty ? 'ল' : name.characters.first;

    final shortcuts = <_Shortcut>[
      if (!guest) ...[
        _Shortcut(
          tr(bn, 'সার্টিফিকেট', 'Certificate'),
          Icons.workspace_premium_rounded,
          SlmColors.gold300,
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CertificatePage()),
          ),
        ),
        _Shortcut(
          tr(bn, 'পিপিই', 'PPE'),
          Icons.health_and_safety_rounded,
          SlmColors.emerald300,
          () => Navigator.of(context).pushNamed(AppRoutes.ppe),
        ),
      ],
      if (auth.isAdmin)
        _Shortcut(
          tr(bn, 'অ্যাডমিন', 'Admin'),
          Icons.admin_panel_settings_rounded,
          SlmColors.gold200,
          () => Navigator.of(context).pushNamed(AppRoutes.admin),
        ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Builder(
          builder: (context) {
            final g = context.slm.layout.gutter;
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
                  ShellSafeArea(
                    child: ListView(
                      padding: shellScrollPadding(context, left: g, top: 0, right: g, extraBottom: 16),
                      children: [
                        SlmTopBar(
                          title: tr(bn, 'সেটিংস', 'Settings'),
                          onBack: () => Navigator.of(context).maybePop(),
                          backLabel: tr(bn, 'ফিরে যান', 'Back'),
                        ),
                        const SizedBox(height: 8),
                        _IdentityHero(
                          name: name,
                          mail: mail,
                          guest: guest,
                          verified: verified,
                          initial: initial,
                          onTick: verified || guest ? null : () => showVerifySheet(context),
                        ),
                        const SizedBox(height: 14),
                        _LanguageRail(
                          bn: bn,
                          onBn: () => ref.read(languageProvider.notifier).setBengali(true),
                          onEn: () => ref.read(languageProvider.notifier).setBengali(false),
                        ),
                        if (!guest) ...[
                          const SizedBox(height: 18),
                          _SectionCue(tr(bn, 'পরিচয়', 'Profile')),
                          const SizedBox(height: 8),
                          _ProfileGrid(
                            tiles: [
                              _TileSpec(tr(bn, 'নাম', 'Name'), _shown(profile?.fullName), () => showNameSheet(context, ref)),
                              _TileSpec(tr(bn, 'জেলা', 'District'), _shown(profile?.district), () => showDistrictSheet(context, ref)),
                              _TileSpec(
                                tr(bn, 'ব্লক', 'Block'),
                                blockReady ? _shown(profile?.block) : '—',
                                blockReady ? () => showBlockSheet(context, ref) : null,
                              ),
                              _TileSpec(tr(bn, 'কাজ', 'Job'), _shown(profile?.job), () => showJobSheet(context, ref)),
                              _TileSpec(tr(bn, 'ফোন', 'Phone'), _shown(profile?.phone), () => showPhoneSheet(context, ref)),
                            ],
                          ),
                        ],
                        if (shortcuts.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionCue(tr(bn, 'সরঞ্জাম', 'Tools')),
                          const SizedBox(height: 8),
                          _ShortcutRail(items: shortcuts),
                        ],
                        const SizedBox(height: 22),
                        if (auth.isAuthenticated)
                          SlmButton(
                            label: tr(bn, 'লগআউট', 'Log out'),
                            icon: Icons.logout_rounded,
                            variant: SlmButtonVariant.danger,
                            size: SlmButtonSize.medium,
                            expand: true,
                            onPressed: () => _confirmSignOut(context, ref, bn),
                          )
                        else
                          GoogleSignInButton(
                            bn: bn,
                            loading: auth.isLoading,
                            error: auth.errorMessage,
                            onPressed: auth.isLoading
                                ? null
                                : () => ref.read(authProvider.notifier).signInWithGoogle(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _shown(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }
}

class _IdentityHero extends StatelessWidget {
  final String name;
  final String mail;
  final bool guest;
  final bool verified;
  final String initial;
  final VoidCallback? onTick;

  const _IdentityHero({
    required this.name,
    required this.mail,
    required this.guest,
    required this.verified,
    required this.initial,
    required this.onTick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152445), SlmColors.navy900, Color(0xFF07111F)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SlmGradients.navyCard,
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7), width: 1.4),
            ),
            child: Text(
              initial,
              style: bangla(fontSize: 24, fontWeight: FontWeight.w800, color: SlmColors.gold200),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: SlmText(name, role: SlmTextRole.title, color: SlmColors.ivory, maxLines: 1),
                    ),
                    if (!guest) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onTick,
                        child: VerifyTick(gold: verified, size: 20),
                      ),
                    ],
                  ],
                ),
                if (!guest && mail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SlmText(mail, role: SlmTextRole.caption, color: SlmColors.gold300, maxLines: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRail extends StatelessWidget {
  final bool bn;
  final VoidCallback onBn;
  final VoidCallback onEn;

  const _LanguageRail({required this.bn, required this.onBn, required this.onEn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SlmColors.navy950.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: _LangPill(label: 'বাংলা', selected: bn, onTap: onBn)),
          Expanded(child: _LangPill(label: 'English', selected: !bn, onTap: onEn)),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: SlmMotion.fast,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? SlmGradients.gold : null,
        ),
        child: Text(
          label,
          style: bangla(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? SlmColors.navy950 : SlmColors.mist,
          ),
        ),
      ),
    );
  }
}

class _SectionCue extends StatelessWidget {
  final String text;

  const _SectionCue(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 1.2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0x00D9B25F), SlmColors.gold400]),
          ),
        ),
        const SizedBox(width: 8),
        SlmText(text, role: SlmTextRole.label, color: SlmColors.gold300),
      ],
    );
  }
}

class _TileSpec {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _TileSpec(this.label, this.value, this.onTap);
}

class _ProfileGrid extends StatelessWidget {
  final List<_TileSpec> tiles;

  const _ProfileGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tile in tiles)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - context.slm.layout.gutter * 2 - 8) / 2,
            child: _ProfileTile(tile: tile),
          ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final _TileSpec tile;

  const _ProfileTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    final enabled = tile.onTap != null;
    return SlmPressable(
      onTap: tile.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: SlmGradients.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SlmColors.gold400.withValues(alpha: enabled ? 0.4 : 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlmText(tile.label, role: SlmTextRole.caption, color: SlmColors.gold300, maxLines: 1),
            const SizedBox(height: 4),
            SlmText(
              tile.value,
              role: SlmTextRole.titleSm,
              color: enabled ? SlmColors.ivory : SlmColors.slate,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Shortcut(this.label, this.icon, this.color, this.onTap);
}

class _ShortcutRail extends StatelessWidget {
  final List<_Shortcut> items;

  const _ShortcutRail({required this.items});

  @override
  Widget build(BuildContext context) {
    final count = items.length.clamp(1, 3);
    final gap = 8.0;
    final width = (MediaQuery.sizeOf(context).width - context.slm.layout.gutter * 2 - gap * (count - 1)) / count;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final item in items)
          SizedBox(
            width: width,
            child: SlmPressable(
              onTap: item.onTap,
              semanticLabel: item.label,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                decoration: BoxDecoration(
                  gradient: SlmGradients.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item.color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.color.withValues(alpha: 0.14),
                        border: Border.all(color: item.color.withValues(alpha: 0.45)),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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
