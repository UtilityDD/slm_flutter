import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../auth/google_mark.dart';
import '../auth/sign_out_confirm.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../rank/league_profile.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'delete_account.dart';
import 'profile_edit.dart';

/// সেটিংস, in this order: profile, league, language, tool library,
/// certificate + PPE, privacy policy, delete account, log out, admin.
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
    final openLink = ref.read(linkOpenerProvider);

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
                        _SectionCue(tr(bn, 'আমার প্রোফাইল', 'My profile')),
                        const SizedBox(height: 8),
                        _ProfileCard(
                          name: name,
                          mail: mail,
                          guest: guest,
                          verified: verified,
                          initial: initial,
                          onStatus: () => showVerifySheet(context),
                          tiles: guest
                              ? const []
                              : [
                                  _TileSpec(tr(bn, 'নাম', 'Name'), _shown(profile?.fullName), () => showNameSheet(context, ref)),
                                  _TileSpec(tr(bn, 'জেলা', 'District'), _shown(profile?.district), () => showDistrictSheet(context, ref)),
                                  _TileSpec(
                                    tr(bn, 'ব্লক', 'Block'),
                                    blockReady ? _shown(profile?.block) : '—',
                                    blockReady ? () => showBlockSheet(context, ref) : null,
                                  ),
                                  _TileSpec(tr(bn, 'কাজ', 'Job'), _shown(profile?.job), () => showJobSheet(context, ref)),
                                ],
                        ),
                        if (!guest) ...[
                          const SizedBox(height: 18),
                          _SectionCue(tr(bn, 'লাইনম্যান লিগ', 'Lineman league')),
                          const SizedBox(height: 8),
                          const LeagueProfileSection(),
                        ],
                        const SizedBox(height: 18),
                        _SectionCue(tr(bn, 'ভাষা', 'Language')),
                        const SizedBox(height: 8),
                        _LanguageRail(
                          bn: bn,
                          onBn: () => ref.read(languageProvider.notifier).setBengali(true),
                          onEn: () => ref.read(languageProvider.notifier).setBengali(false),
                        ),
                        const SizedBox(height: 18),
                        _NavRow(
                          label: tr(bn, 'সরঞ্জাম চিনুন', 'Know your tools'),
                          icon: Icons.manage_search_rounded,
                          color: SlmColors.emerald300,
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.identify),
                        ),
                        if (!guest) ...[
                          _NavRow(
                            label: tr(bn, 'সার্টিফিকেট', 'Certificate'),
                            icon: Icons.workspace_premium_rounded,
                            color: SlmColors.gold300,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const CertificatePage()),
                            ),
                          ),
                          _NavRow(
                            label: tr(bn, 'পিপিই', 'PPE'),
                            icon: Icons.health_and_safety_rounded,
                            color: SlmColors.emerald300,
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.ppe),
                          ),
                        ],
                        _NavRow(
                          label: tr(bn, 'গোপনীয়তা নীতি', 'Privacy policy'),
                          icon: Icons.privacy_tip_outlined,
                          color: SlmColors.gold200,
                          trailing: Icons.open_in_new_rounded,
                          onTap: () => openLink(Uri.parse(AppConfig.privacyPolicyUrl)),
                        ),
                        const SizedBox(height: 22),
                        if (auth.isAuthenticated) ...[
                          SlmButton.ghost(
                            label: tr(bn, 'অ্যাকাউন্ট মুছুন', 'Delete account'),
                            icon: Icons.delete_forever_rounded,
                            size: SlmButtonSize.small,
                            expand: true,
                            onPressed: () => confirmDeleteAccount(context, ref),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () => openLink(Uri.parse(AppConfig.accountDeletionUrl)),
                              child: Text(
                                tr(bn, 'ওয়েবে অ্যাকাউন্ট মোছার নিয়ম', 'Account deletion on the web'),
                                style: bangla(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: SlmColors.mist,
                                ).copyWith(decoration: TextDecoration.underline, decorationColor: SlmColors.mist),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SlmButton(
                            label: tr(bn, 'লগআউট', 'Log out'),
                            icon: Icons.logout_rounded,
                            variant: SlmButtonVariant.danger,
                            size: SlmButtonSize.medium,
                            expand: true,
                            onPressed: () => confirmSignOut(context, ref),
                          ),
                        ] else
                          GoogleSignInButton(
                            bn: bn,
                            loading: auth.isLoading,
                            error: auth.errorMessage,
                            onPressed: auth.isLoading
                                ? null
                                : () => ref.read(authProvider.notifier).signInWithGoogle(),
                          ),
                        if (auth.isAdmin) ...[
                          const SizedBox(height: 14),
                          _NavRow(
                            label: tr(bn, 'অ্যাডমিন', 'Admin'),
                            icon: Icons.admin_panel_settings_rounded,
                            color: SlmColors.gold200,
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.admin),
                          ),
                        ],
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

/// Name, mail and verify tick on top; the editable profile tiles below, in
/// one card.
class _ProfileCard extends StatelessWidget {
  final String name;
  final String mail;
  final bool guest;
  final bool verified;
  final String initial;
  final VoidCallback onStatus;
  final List<_TileSpec> tiles;

  const _ProfileCard({
    required this.name,
    required this.mail,
    required this.guest,
    required this.verified,
    required this.initial,
    required this.onStatus,
    required this.tiles,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SlmPressable(
            onTap: onStatus,
            pressedScale: 0.985,
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
                          const SizedBox(width: 6),
                          VerifyTick(gold: verified, size: 20),
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
          ),
          if (tiles.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ProfileGrid(tiles: tiles),
          ],
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
    return LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tile in tiles)
            SizedBox(
              width: (box.maxWidth - 8) / 2,
              child: _ProfileTile(tile: tile),
            ),
        ],
      ),
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

/// One tappable settings row: tinted icon, label, chevron.
class _NavRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final IconData trailing;
  final VoidCallback onTap;

  const _NavRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing = Icons.chevron_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SlmPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: SlmGradients.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                ),
              ),
              Icon(trailing, color: SlmColors.mist, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
