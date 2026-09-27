class LinemanProfile {
  final String id;
  final String? fullName;
  final String? role;
  final String? slmId;
  final String? avatarUrl;
  final int trainingLevel;
  final int points;
  final int readingPoints;
  final int quizPoints;
  final int totalPenalties;
  final List<String> completedLessons;
  final String? district;
  final String? block;
  final String? job;
  final String? bloodGroup;
  final bool isGuest;

  const LinemanProfile({
    required this.id,
    this.fullName,
    this.role,
    this.slmId,
    this.avatarUrl,
    this.trainingLevel = 1,
    this.points = 0,
    this.readingPoints = 0,
    this.quizPoints = 0,
    this.totalPenalties = 0,
    this.completedLessons = const [],
    this.district,
    this.block,
    this.job,
    this.bloodGroup,
    this.isGuest = false,
  });

  factory LinemanProfile.fromJson(Map<String, dynamic> json) {
    List<String> parseLessons(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return LinemanProfile(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'lineman',
      slmId: json['slm_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      trainingLevel: (json['training_level'] as num?)?.toInt() ?? 1,
      points: (json['points'] as num?)?.toInt() ?? 0,
      readingPoints: (json['reading_points'] as num?)?.toInt() ?? 0,
      quizPoints: (json['quiz_points'] as num?)?.toInt() ?? 0,
      totalPenalties: (json['total_penalties'] as num?)?.toInt() ?? 0,
      completedLessons: parseLessons(json['completed_lessons']),
      district: json['district'] as String?,
      block: json['block'] as String?,
      job: json['job'] as String?,
      bloodGroup: json['blood_group'] as String?,
      isGuest: false,
    );
  }

  factory LinemanProfile.guest() {
    return const LinemanProfile(
      id: 'guest_lineman',
      fullName: 'অতিথি লাইনম্যান (Guest)',
      role: 'guest',
      slmId: 'SLM-GUEST',
      trainingLevel: 1,
      points: 10,
      readingPoints: 0,
      quizPoints: 0,
      district: 'কলকাতা (Kolkata)',
      isGuest: true,
    );
  }

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!;
    }
    if (slmId != null && slmId!.trim().isNotEmpty) {
      return slmId!;
    }
    return 'লাইনম্যান';
  }

  String get badgeTitle {
    if (points >= 5000) return 'মাস্টার লাইনম্যান 🏆';
    if (points >= 2000) return 'সিনিয়র টেকনিশিয়ান ⭐';
    if (points >= 800) return 'দক্ষ লাইনম্যান ⚡';
    if (points >= 200) return 'অগ্রণী লাইনম্যান 🛠️';
    return 'শিক্ষানবিস লাইনম্যান 🌱';
  }
}
