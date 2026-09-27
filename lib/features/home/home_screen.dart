import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weather Alert Banner
          _buildWeatherAlertBanner(isDark),
          const SizedBox(height: 16),

          // User Greeting Card
          _buildGreetingCard(profile, isDark),
          const SizedBox(height: 18),

          // Daily Hourly Status & Activity Ring
          _buildHourlyActivityCard(isDark),
          const SizedBox(height: 18),

          // Section Title: Quick Actions
          const Text(
            'প্রধান কাজ ও অনুশীলন (Quick Actions)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Action Grid
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.timer_outlined,
                  color: AppColors.primaryAmber,
                  title: 'ঘণ্টাভিত্তিক কুইজ',
                  subtitle: 'Catch-up window active',
                  onTap: () => onNavigateTab(3), // Navigate to Quizzes
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.menu_book_rounded,
                  color: AppColors.electricBlue,
                  title: 'দৈনিক পাঠ ও স্কোর',
                  subtitle: '+20 পড়ার পয়েন্ট',
                  onTap: () => onNavigateTab(1), // Navigate to Training
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.visibility_rounded,
                  color: AppColors.safeGreen,
                  title: 'ছবি দেখে চিহ্নিতকরণ',
                  subtitle: 'সরঞ্জাম পরিচিতি কুইজ',
                  onTap: () => onNavigateTab(3),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.shield_outlined,
                  color: AppColors.safetyOrange,
                  title: 'পিপিই চেক ও এসওপি',
                  subtitle: 'নিরাপত্তা সরঞ্জাম গাইড',
                  onTap: () => onNavigateTab(2), // Navigate to SOPs
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Safety Tip Card
          _buildSafetyTipCard(isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.safeGreen.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.safeGreen.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.wb_sunny_rounded,
            color: AppColors.safeGreen,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'আবহাওয়া পরিস্থিতি স্বাভাবিক: কোনো জরুরি প্রাকৃতিক সতর্কতা নেই। কাজ করার সময় বিদ্যুৎ লাইনে সাবধানতা মেনে চলুন।',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.safeGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(dynamic profile, bool isDark) {
    final name = profile?.displayName ?? 'লাইনম্যান ভাই';
    final points = profile?.points ?? 0;
    final level = profile?.trainingLevel ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.slate800, AppColors.slate900]
              : [Colors.white, AppColors.slate100],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryAmber.withValues(alpha: 0.2),
            child: const Icon(
              Icons.engineering_rounded,
              color: AppColors.primaryAmber,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'নমস্কার, $name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'লেভেল $level • মোট অর্জিত পয়েন্ট: $points',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAmber,
                  ),
                ),
                Text(
                  profile?.badgeTitle ?? 'শিক্ষানবিস লাইনম্যান',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.slate200 : AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyActivityCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAmber.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primaryAmber, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.bolt_rounded,
                color: AppColors.primaryAmber,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'দৈনিক কুইজ ও প্র্যাকটিস উইন্ডো',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'আজকের ঘণ্টার প্রশ্ন প্রস্তুত। সঠিক উত্তর দিলে +১০ পয়েন্ট যোগ হবে।',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.slate200 : AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.safetyOrange.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.safetyOrange.withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.safetyOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'আজকের নিরাপত্তা পরামর্শ (Safety Tip)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.safetyOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'পোলে ওঠার আগে সর্বদা পিটিডব্লিউ (PTW - Permit To Work) নিশ্চিত করুন এবং ডিসচার্জ রড দিয়ে লাইন পুরোপুরি আর্থিং করুন। কখনও অনুমান করে লাইনে হাত দেবেন না।',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

