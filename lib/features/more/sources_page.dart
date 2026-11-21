import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'delete_account.dart' show linkOpenerProvider;

/// One official source the safety content is taken from.
class SafetySource {
  const SafetySource(this.titleBn, this.titleEn, this.url);
  final String titleBn;
  final String titleEn;
  final String url;
}

/// The official documents the lessons and levels follow, with the "not a
/// government app" notice (Google Play Misleading Claims policy, 2026-11-17
/// rejection: apps sharing government information must link the source).
/// The same list is in the store description.
abstract final class SafetySources {
  // Owner wording, 2026-11-21.
  static const titleBn = 'তথ্যসূত্র ও ঘোষণা';
  static const titleEn = 'Sources and notice';
  static const noticeBn =
      'এই অ্যাপের নিরাপত্তার নিয়ম নিচের সরকারি ও সংস্থার নথি থেকে নেওয়া। স্মার্ট লাইনম্যান কোনো সরকারি অ্যাপ নয়; WBSEDCL, CEA বা কোনো সরকারি সংস্থার সঙ্গে যুক্ত নয়।';
  static const noticeEn =
      'The safety rules in this app are taken from the official documents below. SmartLineman is not a government app and is not affiliated with WBSEDCL, CEA or any government body.';

  static const all = [
    SafetySource(
      'CEA (নিরাপত্তা ও বিদ্যুৎ সরবরাহ) রেগুলেশন, 2023 — কেন্দ্রীয় বিদ্যুৎ কর্তৃপক্ষ, ভারত সরকার',
      'CEA (Measures relating to Safety and Electric Supply) Regulations, 2023 — Central Electricity Authority, Govt. of India',
      'https://cea.nic.in/regulations/notified-regulations?lang=en',
    ),
    SafetySource(
      'WBSEDCL সেফটি ম্যানুয়াল',
      'WBSEDCL Safety Manual',
      'https://www.wbsedcl.in/irj/go/km/docs/internet/new_website/pdf/Safety_Manual%202025_16_10.pdf',
    ),
    SafetySource(
      'WBSEDCL সেফটি সার্কুলার',
      'WBSEDCL safety circulars',
      'https://portal.wbsedcl.in/irj/go/km/docs/internet/new_website/Safety_Circular.html',
    ),
    SafetySource(
      'WBSEDCL জননিরাপত্তা নির্দেশিকা',
      'WBSEDCL public safety guide',
      'https://www.wbsedcl.in/irj/go/km/docs/internet/new_website/pdf/Public_Safety.pdf',
    ),
    SafetySource(
      'ভারতীয় মান ব্যুরো (BIS) — গ্লাভস, ফিউজ তার, PPE-র IS মান',
      'Bureau of Indian Standards (BIS) — IS standards for gloves, fuse wire and PPE',
      'https://www.bis.gov.in/',
    ),
    SafetySource(
      'বিদ্যুৎ মন্ত্রক, ভারত সরকার',
      'Ministry of Power, Govt. of India',
      'https://powermin.gov.in/',
    ),
  ];
}

class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final openLink = ref.read(linkOpenerProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: SlmTheme.night(),
        child: Builder(
          builder: (context) {
            final g = context.slm.layout.gutter;
            return Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: SlmBackground(constrain: false, child: SizedBox.expand())),
                  ShellSafeArea(
                    child: ListView(
                      key: const ValueKey('sources-list'),
                      padding: shellScrollPadding(context, left: g, top: 0, right: g, extraBottom: 16),
                      children: [
                        SlmTopBar(
                          title: tr(bn, SafetySources.titleBn, SafetySources.titleEn),
                          onBack: () => Navigator.of(context).maybePop(),
                          backLabel: tr(bn, 'ফিরে যান', 'Back'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(bn, SafetySources.noticeBn, SafetySources.noticeEn),
                          style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.ivory, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        for (final s in SafetySources.all) ...[
                          _SourceRow(
                            title: tr(bn, s.titleBn, s.titleEn),
                            url: s.url,
                            onTap: () => openLink(Uri.parse(s.url)),
                          ),
                          const SizedBox(height: 10),
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
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.title, required this.url, required this.onTap});
  final String title;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: title,
      child: Material(
        color: SlmColors.navy800.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: bangla(fontSize: 14.5, fontWeight: FontWeight.w700, color: SlmColors.gold200, height: 1.35)),
                        const SizedBox(height: 4),
                        Text(url, style: bangla(fontSize: 11.5, fontWeight: FontWeight.w500, color: SlmColors.mist, height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new_rounded, size: 20, color: SlmColors.mist),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
