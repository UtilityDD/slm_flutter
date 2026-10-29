import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/slm_backdrop.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../radio/radio_player_provider.dart';
import 'profile_edit.dart';
import '../shell/app_routes.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final guest = auth.isGuest || !auth.isAuthenticated;
    final verified = linemanIsVerified(auth, ref.watch(verifyHoldProvider));
    final name = guest
        ? tr(bn, 'অতিথি', 'Guest')
        : (profile?.displayName ?? tr(bn, 'লাইনম্যান', 'Lineman'));
    final mail = auth.email?.trim() ?? '';
    final district = profile?.district?.trim() ?? '';
    final blockReady = district.isNotEmpty;

    final tools = <_Row>[
      _Row(
        tr(bn, 'জরুরি', 'Emergency'),
        Icons.warning_rounded,
        const Color(0xFFDC2626),
        () {
          Navigator.of(context).pushNamed(AppRoutes.emergency);
        },
      ),
      _Row(
        tr(bn, 'আমার পিপিই', 'My PPE'),
        Icons.health_and_safety_rounded,
        const Color(0xFF0F766E),
        () {
          Navigator.of(context).pushNamed(AppRoutes.ppe);
        },
      ),
      _Row(
        tr(bn, 'রেডিও', 'Radio'),
        Icons.radio_rounded,
        const Color(0xFFC2410C),
        () {
          ref.read(radioProvider.notifier).showPlayer();
          ref.read(radioProvider.notifier).togglePlay();
        },
      ),
      if (auth.isAdmin)
        _Row(
          tr(bn, 'অ্যাডমিন', 'Admin'),
          Icons.admin_panel_settings_rounded,
          const Color(0xFF1E3A8A),
          () {
            Navigator.of(context).pushNamed(AppRoutes.admin);
          },
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SlmBackdrop(
        child: ShellSafeArea(
          child: ListView(
            padding: shellScrollPadding(
              context,
              left: 24,
              top: 4,
              right: 24,
              extraBottom: 12,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.ink,
                  ),
                  tooltip: tr(bn, 'ফিরে যান', 'Back'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bangla(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: verified ? null : () => showVerifySheet(context),
                    child: VerifyTick(gold: verified, size: 26),
                  ),
                ],
              ),
              if (!guest && mail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  mail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bangla(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
              if (!guest) ...[
                const SizedBox(height: 22),
                _SectionLabel(tr(bn, 'আমার পরিচয়', 'My details')),
                const SizedBox(height: 8),
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
                      value: blockReady
                          ? _shown(profile?.block)
                          : tr(bn, 'আগে জেলা', 'District first'),
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
                const SizedBox(height: 18),
                _SectionLabel(tr(bn, 'আমার কাগজ', 'My papers')),
                const SizedBox(height: 8),
                _Card(
                  children: [
                    _AccountRow(
                      row: _Row(
                        tr(bn, 'সার্টিফিকেট', 'Certificate'),
                        Icons.workspace_premium_rounded,
                        const Color(0xFFB45309),
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CertificatePage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (!guest) ...[
                const SizedBox(height: 18),
                _Card(
                  children: [for (final tool in tools) _AccountRow(row: tool)],
                ),
              ],
              const SizedBox(height: 18),
              if (auth.isAuthenticated)
                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: Text(
                    tr(bn, 'লগআউট', 'Log out'),
                    style: bangla(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.alertRed,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.login),
                  child: Text(
                    tr(bn, 'লগইন', 'Log in'),
                    style: bangla(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shown(String? raw) {
    final text = raw?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: bangla(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(children: _withDividers(children)),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const Divider(height: 1, color: Color(0xFFF1EBE4)));
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
    final ink = enabled ? AppColors.ink : AppColors.muted;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: bangla(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: bangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(row.icon, color: row.ink, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                row.label,
                style: bangla(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
