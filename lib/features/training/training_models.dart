import '../../core/config/app_config.dart';

enum LadderStepStatus {
  completed,
  active,
  locked,
}

class TrainingModuleItem {
  final int moduleNumber;
  final String title;
  final String badgeName;
  final int totalLessons;
  final int completedLessons;
  final LadderStepStatus status;

  const TrainingModuleItem({
    required this.moduleNumber,
    required this.title,
    required this.badgeName,
    required this.totalLessons,
    required this.completedLessons,
    required this.status,
  });

  bool get isCompleted => status == LadderStepStatus.completed;
  bool get isActive => status == LadderStepStatus.active;
  bool get isLocked => status == LadderStepStatus.locked;
}

class LessonSectionPoint {
  final String itemName;
  final String? importance;
  final String? dailyCheck;
  final String? specifications;
  final String? imageName;
  final String? imageCaption;

  const LessonSectionPoint({
    required this.itemName,
    this.importance,
    this.dailyCheck,
    this.specifications,
    this.imageName,
    this.imageCaption,
  });

  String? get fullImageUrl {
    if (imageName == null || imageName!.isEmpty) return null;
    final raw = imageName!.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (raw.contains('drive.google.com')) {
        final match = RegExp(r'/d/(.+?)/|id=(.+?)(&|$)').firstMatch(raw);
        final id = match?.group(1) ?? match?.group(2) ?? '';
        if (id.isNotEmpty) {
          final day = DateTime.now().toIso8601String().split('T').first;
          return 'https://lh3.googleusercontent.com/u/0/d/$id?v=$day';
        }
      }
      return raw;
    }
    if (raw.startsWith('/')) return '${AppConfig.websiteUrl}$raw';
    if (raw.startsWith('images/')) return '${AppConfig.websiteUrl}/$raw';
    return '${AppConfig.websiteUrl}/quizzes/${raw.replaceFirst(RegExp(r'^/'), '')}';
  }
}

class LessonMythItem {
  final String myth;
  final String reality;

  const LessonMythItem({
    required this.myth,
    required this.reality,
  });
}

class LessonCardItem {
  final String id;
  final int moduleNumber;
  final int chapterNumber;
  final String title;
  final String? missionBriefing;
  final List<String> proTips;
  final List<LessonSectionPoint> points;
  final List<LessonMythItem> myths;
  final bool isCompleted;

  const LessonCardItem({
    required this.id,
    required this.moduleNumber,
    required this.chapterNumber,
    required this.title,
    this.missionBriefing,
    this.proTips = const [],
    this.points = const [],
    this.myths = const [],
    this.isCompleted = false,
  });

  factory LessonCardItem.fromSupabase(Map<String, dynamic> row, bool completed) {
    final content = row['content'] as Map<String, dynamic>? ?? {};

    // 1. Parse Mission Briefing
    final rawMission = content['mission_briefing']?.toString();

    // 2. Parse Pro Tips
    final List<String> parsedProTips = [];
    final rawProTip = content['pro_tip'];
    if (rawProTip is Map) {
      if (rawProTip['tip'] != null) parsedProTips.add(rawProTip['tip'].toString());
      if (rawProTip['points'] is List) {
        for (final p in rawProTip['points']) {
          if (p != null) parsedProTips.add(p.toString());
        }
      }
    } else if (rawProTip != null) {
      parsedProTips.add(rawProTip.toString());
    }

    // 3. Parse Section Points
    final List<LessonSectionPoint> parsedPoints = [];
    final rawSections = content['sections'];
    if (rawSections is List) {
      for (final sec in rawSections) {
        if (sec is Map) {
          if (sec['points'] is List) {
            for (final pt in sec['points']) {
              if (pt is Map) {
                parsedPoints.add(LessonSectionPoint(
                  itemName: pt['item_name']?.toString() ?? '',
                  importance: pt['importance']?.toString(),
                  dailyCheck: pt['daily_check']?.toString(),
                  specifications: pt['specifications']?.toString(),
                  imageName: pt['image_name']?.toString(),
                  imageCaption: pt['image_caption']?.toString(),
                ));
              }
            }
          } else if (sec['title'] != null || sec['body'] != null) {
            parsedPoints.add(LessonSectionPoint(
              itemName: sec['title']?.toString() ?? 'নির্দেশনা',
              importance: sec['body']?.toString() ?? sec['text']?.toString(),
            ));
          }
        }
      }
    }

    // 4. Parse Myths
    final List<LessonMythItem> parsedMyths = [];
    final rawMythBuster = content['myth_buster'];
    if (rawMythBuster is Map) {
      if (rawMythBuster['myths'] is List) {
        for (final m in rawMythBuster['myths']) {
          if (m is Map) {
            parsedMyths.add(LessonMythItem(
              myth: m['myth']?.toString() ?? '',
              reality: m['reality']?.toString() ?? '',
            ));
          }
        }
      } else if (rawMythBuster['myth'] != null) {
        parsedMyths.add(LessonMythItem(
          myth: rawMythBuster['myth']?.toString() ?? '',
          reality: rawMythBuster['reality']?.toString() ?? '',
        ));
      }
    }

    return LessonCardItem(
      id: row['id']?.toString() ?? '',
      moduleNumber: (row['module_number'] as num?)?.toInt() ?? 1,
      chapterNumber: (row['chapter_number'] as num?)?.toInt() ?? 1,
      title: row['title']?.toString() ?? '',
      missionBriefing: rawMission,
      proTips: parsedProTips,
      points: parsedPoints,
      myths: parsedMyths,
      isCompleted: completed,
    );
  }
}
