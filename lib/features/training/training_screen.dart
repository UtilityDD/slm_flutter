import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TrainingChapter {
  final int number;
  final String title;
  final String description;
  final int totalLessons;
  final int completedLessons;
  final bool isCompleted;

  const TrainingChapter({
    required this.number,
    required this.title,
    required this.description,
    required this.totalLessons,
    required this.completedLessons,
    this.isCompleted = false,
  });
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  static const List<TrainingChapter> chapters = [
    TrainingChapter(
      number: 1,
      title: 'ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) ও সাধারণ সতর্কতা',
      description: 'হেলমেট, ইনসুলেটিং গ্লাভস, সেফটি বেল্ট ও বুটের সঠিক ব্যবহার ও পরিদর্শন।',
      totalLessons: 10,
      completedLessons: 10,
      isCompleted: true,
    ),
    TrainingChapter(
      number: 2,
      title: 'পোল ও লাইনে আরোহণ পদ্ধতি',
      description: 'ল্যাডার, ক্লাইম্বিং বেল্ট ও পোল পরীক্ষার বৈজ্ঞানিক নিয়ম।',
      totalLessons: 10,
      completedLessons: 6,
    ),
    TrainingChapter(
      number: 3,
      title: 'কন্ডাক্টর ও তারের নিরাপদ টান ও হ্যান্ডলিং',
      description: 'এসিরএসআর (ACSR) কন্ডাক্টর, স্যাগিং ও জাম্পারিং কাজের সতর্কতা।',
      totalLessons: 10,
      completedLessons: 2,
    ),
    TrainingChapter(
      number: 4,
      title: 'ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR) রক্ষণাবেক্ষণ',
      description: 'ট্রান্সফরমার আইসোলেশন, ডিও ফিউজ প্রতিস্থাপন ও লোড ভারসাম্য।',
      totalLessons: 10,
      completedLessons: 0,
    ),
    TrainingChapter(
      number: 5,
      title: 'সঠিক আর্থিং ও ডিসচার্জ রড প্রয়োগ',
      description: 'আর্থিং প্রতিরোধ পরিমাপ, ডিসচার্জ পদ্ধতি এবং রিভার্স ফিড প্রটেকশন।',
      totalLessons: 10,
      completedLessons: 0,
    ),
    TrainingChapter(
      number: 6,
      title: 'এলটি ও এইচটি লাইনে ফল্ট নির্ণয়',
      description: 'লাইনের শর্ট সার্কিট, আর্থ ফল্ট শনাক্তকরণ ও জরুরি মেরামত।',
      totalLessons: 10,
      completedLessons: 0,
    ),
    TrainingChapter(
      number: 7,
      title: 'বিদ্যুৎস্পৃষ্টের জরুরি উদ্ধার ও সিপিআর (CPR)',
      description: 'জরুরি পরিস্থিতিতে জীবনের সুরক্ষা ও রক্তক্ষরণ প্রতিরোধ।',
      totalLessons: 10,
      completedLessons: 0,
    ),
    TrainingChapter(
      number: 8,
      title: 'ডব্লিউবিইআরসি (WBERC) ও কেন্দ্রীয় বিদ্যুৎ নিরাপত্তা নিয়ম',
      description: 'স্ট্যান্ডার্ড অপারেটিং রেগুলেশন ও আইনি দিকসমূহ।',
      totalLessons: 10,
      completedLessons: 0,
    ),
    TrainingChapter(
      number: 9,
      title: 'স্মার্ট মিটার ও আধুনিক মিটারিং টুলস',
      description: 'স্মার্ট মিটার ইন্সটলেশন ও ফিল্ড টেস্ট নিরাপত্তা।',
      totalLessons: 10,
      completedLessons: 0,
    ),
    TrainingChapter(
      number: 10,
      title: 'ফিল্ড সেফটি ম্যানুয়াল ও চেকলিস্ট',
      description: 'কাজের পূর্বে ও পরে সাইট পরিদর্শনের সম্পূর্ণ চেকলিস্ট।',
      totalLessons: 18,
      completedLessons: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.electricBlue, Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'সুরক্ষা প্রশিক্ষণ ও পাঠ্যক্রম',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'প্রতিটি অধ্যায় পাঠ সম্পন্ন করে রিডিং গেট যাচাই করুন এবং প্রতি ৩০ দিনে পুনরায় ২০ বোনাস পয়েন্ট অর্জন করুন।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chapter List
          ...chapters.map((chapter) => _buildChapterTile(context, chapter, isDark)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChapterTile(BuildContext context, TrainingChapter chapter, bool isDark) {
    final progress = chapter.completedLessons / chapter.totalLessons;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chapter.isCompleted
              ? AppColors.safeGreen.withValues(alpha: 0.5)
              : (isDark ? AppColors.slate700 : AppColors.slate200),
          width: chapter.isCompleted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: chapter.isCompleted
                      ? AppColors.safeGreen
                      : (isDark ? AppColors.slate700 : AppColors.slate100),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: chapter.isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : Text(
                          '${chapter.number}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'অধ্যায় ${chapter.number}: ${chapter.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.slate200 : AppColors.slate700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? AppColors.slate700 : AppColors.slate100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      chapter.isCompleted ? AppColors.safeGreen : AppColors.primaryAmber,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${chapter.completedLessons}/${chapter.totalLessons} পাঠ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

