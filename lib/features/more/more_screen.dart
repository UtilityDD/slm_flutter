import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../radio/radio_player_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Profile Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryAmber.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded, color: AppColors.primaryAmber, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.displayName ?? 'লাইনম্যান',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'আইডি: ${profile?.slmId ?? "SLM-000"} • জেলা: ${profile?.district ?? "পশ্চিমবঙ্গ"}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        profile?.badgeTitle ?? 'শিক্ষানবিস লাইনম্যান',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryAmber),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Emergency Section
        _buildSectionHeader('জরুরি ও সহায়তা (Emergency Services)'),
        _buildListTile(
          icon: Icons.phone_in_talk_rounded,
          color: AppColors.alertRed,
          title: 'পশ্চিমবঙ্গ জেলাভিত্তিক জরুরি নম্বর',
          subtitle: 'বিদ্যুৎ দপ্তর, ফায়ার স্টেশন ও হাসপাতাল ডিরেক্টরি',
          onTap: () => _callEmergency('19121'),
          isDark: isDark,
        ),
        _buildListTile(
          icon: Icons.emergency_rounded,
          color: AppColors.alertRed,
          title: 'সরাসরি বিদ্যুৎ হেল্পলাইন (19121)',
          subtitle: '২৪x৭ ২৪ ঘণ্টা সেন্ট্রাল বিদ্যুৎ অভিযোগ',
          onTap: () => _callEmergency('19121'),
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        // Radio & Audio
        _buildSectionHeader('অডিও ও বিনোদন'),
        _buildListTile(
          icon: Icons.radio_rounded,
          color: AppColors.electricBlue,
          title: 'লাইফস্কিল রেডিও চালু/বন্ধ',
          subtitle: 'নিরাপত্তা গল্প ও মোটিভেশনাল পডকাস্ট',
          onTap: () {
            ref.read(radioProvider.notifier).showPlayer();
            ref.read(radioProvider.notifier).togglePlay();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        // App Info & Settings
        _buildSectionHeader('অ্যাপ তথ্য ও সহায়তা'),
        _buildListTile(
          icon: Icons.info_outline_rounded,
          color: AppColors.primaryAmber,
          title: 'অ্যাপ সংস্করণ (Version)',
          subtitle: 'SmartLineman Flutter v${AppConfig.appVersion}',
          onTap: () {},
          isDark: isDark,
        ),
        _buildListTile(
          icon: Icons.mail_outline_rounded,
          color: AppColors.primaryAmber,
          title: 'সহায়তা ও যোগাযোগ',
          subtitle: AppConfig.supportEmail,
          onTap: () => _openUrl('mailto:${AppConfig.supportEmail}'),
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        // Auth Actions
        if (authState.isAuthenticated)
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.alertRed),
            label: const Text('লগআউট করুন (Log Out)', style: TextStyle(color: AppColors.alertRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.alertRed),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.login_rounded, color: AppColors.slate900),
            label: const Text('লগইন করুন (Login)', style: TextStyle(color: AppColors.slate900, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAmber,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      ),
    );
  }

  void _callEmergency(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

