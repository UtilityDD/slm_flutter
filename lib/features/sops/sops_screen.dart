import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SopsScreen extends StatefulWidget {
  final int initialIndex;
  final String title;

  const SopsScreen({
    super.key,
    this.initialIndex = 0,
    this.title = 'পিপিই ও কাজের নিয়ম',
  });

  @override
  State<SopsScreen> createState() => _SopsScreenState();
}

class _SopsScreenState extends State<SopsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _ppeChecklist = [
    {
      'id': 1,
      'emoji': '🪖',
      'title': 'সেফটি হেলমেট',
      'subtitle': 'থুতনির ফিতে ও জালি চেক',
      'desc': 'থুতনির ফিতে (চিন স্ট্র্যাপ) ও ভেতরের জালি শক্ত করে বাঁধা আছে তো? ফাটল থাকলে বাতিল করুন।',
      'checked': false,
    },
    {
      'id': 2,
      'emoji': '🧤',
      'title': '১১ কেভি ইনসুলেটিং গ্লাভস',
      'subtitle': 'এয়ার টেস্ট ও লিক চেক',
      'desc': 'মুখে হাওয়া দিয়ে এয়ার টেস্ট করুন—কোনো সূক্ষ্ম ছিদ্র বা লিক নেই তো? তেল-কালি মুক্ত রাখুন।',
      'checked': false,
    },
    {
      'id': 3,
      'emoji': '🥾',
      'title': 'ডাই-ইলেকট্রিক সেফটি বুট',
      'subtitle': 'সোলে পেরেক বা তার নেই তো?',
      'desc': 'জুতোর সোলে কোনো পেরেক, বাঁধার তার বা লোহার টুকরো বিঁধে নেই তো? ভিজে বুট পরবেন না।',
      'checked': false,
    },
    {
      'id': 4,
      'emoji': '🧗',
      'title': 'ফুল বডি সেফটি হারনেস',
      'subtitle': 'কোমর-রশা নয়, ডাবল ল্যানিয়ার্ড',
      'desc': 'কোমর-রশায় পেট ও শিরদাঁড়া নষ্ট হয়। ফুল বডি হারনেসের ডাবল হুক ও শক-অ্যাবজরবার চেক করুন।',
      'checked': false,
    },
    {
      'id': 5,
      'emoji': '⚡',
      'title': 'ডিসচার্জ ও আর্থিং রড',
      'subtitle': 'লাইনে হাত দেওয়ার আগে আর্থিং',
      'desc': 'শাটডাউন নেওয়ার পর দুই পাশেই আর্থিং রড দিয়ে শর্ট করে নিশ্চিত আর্থিং করুন। ব্যাকফিডিং মারাত্মক!',
      'checked': false,
    },
    {
      'id': 6,
      'emoji': '🥽',
      'title': 'সেফটি গগলস / ফেস শিল্ড',
      'subtitle': 'আর্কিং ফ্ল্যাশ থেকে চোখ রক্ষা',
      'desc': 'জাম্পার বাঁধা বা ফিউজ লাগানোর সময় হঠাৎ স্পার্ক ও আর্কিং আগুনের শিখা থেকে চোখ সুরক্ষিত রাখুন।',
      'checked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _checkedCount => _ppeChecklist.where((item) => item['checked'] == true).length;

  void _resetChecklist() {
    setState(() {
      for (final item in _ppeChecklist) {
        item['checked'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryAmber,
          indicatorWeight: 3,
          labelColor: AppColors.primaryAmber,
          unselectedLabelColor: isDark ? Colors.white70 : AppColors.slate700,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'পিপিই'),
            Tab(text: '৮ মন্ত্র'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPpeChecklistView(isDark),
          _buildFieldSopView(isDark),
        ],
      ),
    );
  }

  Widget _buildPpeChecklistView(bool isDark) {
    final allChecked = _checkedCount == _ppeChecklist.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Top Inspection Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: allChecked
                  ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
                  : (isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF1F5F9)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: allChecked ? Colors.greenAccent : AppColors.primaryAmber,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: (allChecked ? Colors.green : Colors.black).withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                allChecked ? '🟢' : '⚠️',
                style: const TextStyle(fontSize: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allChecked
                          ? 'সবুজ সংকেত! আপনি সুরক্ষিত ✅'
                          : 'পোলে ওঠার আগে ৬টি পিপিই চেক করুন',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: allChecked ? Colors.white : (isDark ? Colors.white : AppColors.slate900),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allChecked
                          ? 'সব সরঞ্জাম সম্পূর্ণ ও প্রস্তুত। এবার নিরাপদে পোলে উঠুন ওস্তাদ!'
                          : 'যাচাই করা হয়েছে: /টি সরঞ্জাম',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: allChecked ? Colors.white70 : (isDark ? Colors.white60 : AppColors.slate700),
                      ),
                    ),
                  ],
                ),
              ),
              if (_checkedCount > 0)
                IconButton(
                  onPressed: _resetChecklist,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: allChecked ? Colors.white : AppColors.primaryAmber,
                  ),
                  tooltip: 'পুনরায় শুরু করুন',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of 6 Large Inspection Cards
        ..._ppeChecklist.map((item) {
          final isChecked = item['checked'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isChecked ? AppColors.safeGreen : (isDark ? AppColors.slate700 : AppColors.slate200),
                width: isChecked ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isChecked ? AppColors.safeGreen : Colors.black).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    item['checked'] = !isChecked;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Icon
                      Text(item['emoji'] as String, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isChecked ? AppColors.safeGreen : (isDark ? Colors.white : AppColors.slate900),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryAmber,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['desc'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: isDark ? Colors.white70 : AppColors.slate800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Big Checkbox
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isChecked ? AppColors.safeGreen : Colors.transparent,
                          border: Border.all(
                            color: isChecked ? AppColors.safeGreen : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildFieldSopView(bool isDark) {
    final sops = [
      {
        'num': '১',
        'title': 'শাটডাউন ও লাইন বিচ্ছিন্নকরণ (PTW)',
        'rule': 'আগে শাটডাউন নিশ্চিত করুন, টেস্টার দিয়ে ভোল্টেজ পরীক্ষা করুন, তারপর দুই প্রান্তে ডিসচার্জ ও আর্থিং রড লাগান। মনে খটকা থাকলে কখনও লাইনে হাত দেবেন না।',
        'color': AppColors.safetyOrange,
      },
      {
        'num': '২',
        'title': 'পোলে ওঠার ৩-পয়েন্ট নীতি',
        'rule': 'পোলে ওঠার সময় সব সময় দুটি হাত ও একটি পা, অথবা দুটি পা ও একটি হাত পোলে বা সিঁড়িতে আটকে থাকবে। কোমর-রশা নয়—ফুল বডি হারনেসের ডাবল ল্যানিয়ার্ড ব্যবহার করুন।',
        'color': const Color(0xFF2563EB),
      },
      {
        'num': '৩',
        'title': 'ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR) সার্ভিসিং',
        'rule': 'এইচটি (11kV) ড্রপআউট ফিউজ নামানোর পর এলটি সার্কিট ব্রেকারও অফ করুন। ব্যাকফিডিং এড়াতে উভয় পাশেই শর্ট সার্কিট আর্থিং লাগান।',
        'color': AppColors.primaryAmber,
      },
      {
        'num': '৪',
        'title': 'ঝড়-বৃষ্টি ও দুর্যোগে কাজ',
        'rule': 'ঝড়-বৃষ্টি চলাকালীন ওভারহেড লাইনে কাজ বন্ধ রাখুন। ভেজা পোল ও কন্ডাক্টরে বিদ্যুৎ চমকানোর সময় কাজ করা মারাত্মক ঝুঁকিপূর্ণ।',
        'color': const Color(0xFFDC2626),
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate800 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryAmber, width: 1.5),
          ),
          child: const Row(
            children: [
              Text('📜', style: TextStyle(fontSize: 30)),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'মাঠের ৪টি অপরিবর্তনীয় নিয়ম: কোনো তাড়াহুড়ো নয়, আগে জীবন তারপর কাজ!',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...sops.map((sop) {
          final color = sop['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          sop['num'] as String,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sop['title'] as String,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  sop['rule'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: isDark ? Colors.white70 : AppColors.slate800,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }
}
