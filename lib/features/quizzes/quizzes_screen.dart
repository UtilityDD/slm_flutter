import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: isDark ? AppColors.slate900 : Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryAmber,
            labelColor: AppColors.primaryAmber,
            unselectedLabelColor: isDark ? Colors.white70 : AppColors.slate700,
            tabs: const [
              Tab(text: 'কুইজ ও অনুশীলন'),
              Tab(text: 'মাসিক লিডারবোর্ড 🏆'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizPracticeView(isDark),
          _buildLeaderboardView(isDark),
        ],
      ),
    );
  }

  Widget _buildQuizPracticeView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hourly Catchup Window Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFB45309)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.alarm_on_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'ঘণ্টাভিত্তিক কুইজ (Hourly Quiz Window)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'প্রতি ঘণ্টার প্রশ্নের উত্তর দিন। ভুল উত্তরের ক্ষেত্রে পেনাল্টি পয়েন্ট গণনা করা হয়।',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded, color: AppColors.slate900),
                label: const Text(
                  'কুইজ শুরু করুন (+১০ পয়েন্ট)',
                  style: TextStyle(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Visual Equipment Identification
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.image_search_rounded, color: AppColors.safeGreen, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'ছবি দেখে সরঞ্জাম চিহ্নিতকরণ (Visual Identify)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'সাবস্টেশন, ট্রান্সফরমার এবং বিতরণ লাইনের হাই-রেজোলিউশন ছবি দেখে সরঞ্জামটির সঠিক নাম চিহ্নিত করুন।',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                label: const Text('অনুশীলন শুরু করুন'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.safeGreen,
                  side: const BorderSide(color: AppColors.safeGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardView(bool isDark) {
    final topLinemen = [
      {'rank': 1, 'name': 'শুভঙ্কর জানা', 'district': 'পূর্ব মেদিনীপুর', 'points': 4820, 'badge': '🥇'},
      {'rank': 2, 'name': 'প্রদীপ চক্রবর্তী', 'district': 'বাঁকুড়া', 'points': 4650, 'badge': '🥈'},
      {'rank': 3, 'name': 'অমল রায়', 'district': 'হুগলি', 'points': 4410, 'badge': '🥉'},
      {'rank': 4, 'name': 'বিশ্বজিৎ মন্ডল', 'district': 'বর্ধমান', 'points': 3980, 'badge': '4'},
      {'rank': 5, 'name': 'রাজেশ পাত্র', 'district': 'দক্ষিণ ২৪ পরগনা', 'points': 3740, 'badge': '5'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trophy Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF115E59)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'মাসিক উৎসাহ বোর্ড (Monthly Boards)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'নিয়মিত পাঠ ও সঠিক কুইজের মাধ্যমে পয়েন্ট অর্জন করে শীর্ষে থাকুন।',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...topLinemen.map((lineman) {
          final isTop3 = (lineman['rank'] as int) <= 3;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTop3 ? AppColors.primaryAmber.withValues(alpha: 0.5) : (isDark ? AppColors.slate700 : AppColors.slate200),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    lineman['badge'].toString(),
                    style: TextStyle(
                      fontSize: isTop3 ? 20 : 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lineman['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        lineman['district'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${lineman['points']} পয়েন্ট',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryAmber,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

