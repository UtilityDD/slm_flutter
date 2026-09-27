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

class LessonCardItem {
  final String id;
  final int moduleNumber;
  final int chapterNumber;
  final String title;
  final String? missionBriefing;
  final String? proTip;
  final String? mythBuster;
  final List<String> sections;
  final bool isCompleted;

  const LessonCardItem({
    required this.id,
    required this.moduleNumber,
    required this.chapterNumber,
    required this.title,
    this.missionBriefing,
    this.proTip,
    this.mythBuster,
    this.sections = const [],
    this.isCompleted = false,
  });

  factory LessonCardItem.fromSupabase(Map<String, dynamic> row, bool completed) {
    final content = row['content'] as Map<String, dynamic>? ?? {};
    
    List<String> parseSections(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((s) {
          if (s is Map && s['body'] != null) return s['body'].toString();
          if (s is Map && s['text'] != null) return s['text'].toString();
          return s.toString();
        }).toList();
      }
      return [];
    }

    return LessonCardItem(
      id: row['id']?.toString() ?? '',
      moduleNumber: (row['module_number'] as num?)?.toInt() ?? 1,
      chapterNumber: (row['chapter_number'] as num?)?.toInt() ?? 1,
      title: row['title']?.toString() ?? '',
      missionBriefing: content['mission_briefing']?.toString(),
      proTip: content['pro_tip'] is Map ? content['pro_tip']['tip']?.toString() : content['pro_tip']?.toString(),
      mythBuster: content['myth_buster'] is Map ? content['myth_buster']['myth']?.toString() : content['myth_buster']?.toString(),
      sections: parseSections(content['sections']),
      isCompleted: completed,
    );
  }
}
