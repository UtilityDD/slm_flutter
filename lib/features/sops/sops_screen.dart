import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SopsScreen extends StatefulWidget {
  const SopsScreen({super.key});

  @override
  State<SopsScreen> createState() => _SopsScreenState();
}

class _SopsScreenState extends State<SopsScreen> with SingleTickerProviderStateMixin {
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
              Tab(text: 'নিরাপত্তা সরঞ্জাম (PPE)'),
              Tab(text: 'স্ট্যান্ডার্ড এসওপি (SOP)'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPpeView(isDark),
          _buildSopListView(isDark),
        ],
      ),
    );
  }

  Widget _buildPpeView(bool isDark) {
    final ppeItems = [
      {'name': 'নিরাপত্তা হেলমেট (Class E/G)', 'standard': 'IS 2925 (Tested for 20kV shock resistance)', 'icon': Icons.security_rounded},
      {'name': '১১ কেভি বৈদ্যুতিক ইনসুলেটিং গ্লাভস', 'standard': 'IS 4770 Class 1 / Class 2 (Dielectric tested)', 'icon': Icons.pan_tool_rounded},
      {'name': 'ফুল বডি সেফটি হারনেস ও বেল্ট', 'standard': 'IS 3521:1999 (Dual lanyard with shock absorber)', 'icon': Icons.accessibility_new_rounded},
      {'name': 'ডাই-ইলেকট্রিক সেফটি বুট', 'standard': 'IS 15298 (Steel toe cap + 14kV dielectric sole)', 'icon': Icons.do_not_step_rounded},
      {'name': 'ডিসচার্জ ও আর্থিং রড', 'standard': 'FRP Telescopic discharge rod with copper earth clamp', 'icon': Icons.horizontal_rule_rounded},
      {'name': 'সেফটি গগলস / ফেস শিল্ড', 'standard': 'Anti-arc flash polycarbonate protective visor', 'icon': Icons.visibility_rounded},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Lineman Illustration Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.slate800, AppColors.slate900]
                  : [Colors.amber.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryAmber.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.safetyOrange, size: 40),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ব্যক্তিগত সুরক্ষা সরঞ্জাম (My PPE)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'কাজে বেরোনোর আগে নিশ্চিত করুন আপনার সমস্ত ব্যক্তিগত সুরক্ষা সরঞ্জাম অক্ষত ও কাজের উপযোগী।',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...ppeItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: AppColors.primaryAmber, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['standard'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.safeGreen, size: 22),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSopListView(bool isDark) {
    final sops = [
      {'title': 'SOP-01: ১১ কেভি ওভারহেড লাইনে শাটডাউন ও পিটিডব্লিউ গ্রহণ', 'type': 'Mandatory'},
      {'title': 'SOP-02: ডিস্ট্রিবিউশন ট্রান্সফরমার ড্রপআউট (DO) ফিউজ প্রতিস্থাপন', 'type': 'High Voltage'},
      {'title': 'SOP-03: ঝড়-বৃষ্টির পর ক্ষতিগ্রস্ত কন্ডাক্টর মেরামত ও আর্থিং', 'type': 'Emergency'},
      {'title': 'SOP-04: এবি সুইচ (AB Switch) নিরাপদ পরিচালনা ও ইন্টারলকিং', 'type': 'Switching'},
      {'title': 'SOP-05: এলটি বিতরণ বক্সে কেবল টার্মিনেশন ও লোড ভারসাম্য', 'type': 'Distribution'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sops.length,
      itemBuilder: (context, index) {
        final sop = sops[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.electricBlue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sop['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sop['type']!,
                        style: const TextStyle(fontSize: 10, color: AppColors.electricBlue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}

