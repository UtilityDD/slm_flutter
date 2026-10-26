import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/models/lineman_profile.dart';

class CautionPin {
  final String labelBn;
  final String labelEn;
  final IconData icon;
  final bool earned;

  const CautionPin({
    required this.labelBn,
    required this.labelEn,
    required this.icon,
    required this.earned,
  });
}

class LinemanPath {
  final int achieved;
  final double towardNext;
  final double battery;
  final List<CautionPin> pins;

  const LinemanPath({
    required this.achieved,
    required this.towardNext,
    required this.battery,
    required this.pins,
  });

  int get lastPage => math.min(10, achieved + 1);
}

const linemanChapters = [
  ('ট্রেইনি', 'Trainee', Icons.health_and_safety_rounded),
  ('জুনিয়র', 'Junior', Icons.link_rounded),
  ('টেকনিশিয়ান', 'Technician', Icons.bolt_rounded),
  ('স্কিলড', 'Skilled', Icons.settings_rounded),
  ('অ্যাডভান্সড', 'Advanced', Icons.vertical_align_bottom_rounded),
  ('সিনিয়র', 'Senior', Icons.flashlight_on_rounded),
  ('সুপারভাইজার', 'Supervisor', Icons.medical_services_rounded),
  ('স্পেশালিস্ট', 'Specialist', Icons.badge_rounded),
  ('এক্সপার্ট', 'Expert', Icons.speed_rounded),
  ('সেফটি প্রো', 'Safety Pro', Icons.fact_check_rounded),
];

int webBadgeLevel(LinemanProfile? profile) {
  var level = profile?.trainingLevel ?? 1;
  if (level < 1) level = 1;
  final reading = profile?.readingPoints ?? 0;
  if (reading >= 1980) {
    level = math.max(level, 10);
  } else if (reading >= 1780) {
    level = math.max(level, 9);
  } else if (reading >= 1580) {
    level = math.max(level, 9);
  } else if (reading >= 1380) {
    level = math.max(level, 8);
  } else if (reading >= 1180) {
    level = math.max(level, 7);
  } else if (reading >= 980) {
    level = math.max(level, 6);
  } else if (reading >= 780) {
    level = math.max(level, 5);
  } else if (reading >= 580) {
    level = math.max(level, 4);
  } else if (reading >= 380) {
    level = math.max(level, 3);
  } else if (reading >= 180) {
    level = math.max(level, 2);
  }
  if (level > 10) level = 10;
  return level;
}

String linemanBadgeName(int level, bool bn) {
  final index = (level - 1).clamp(0, linemanChapters.length - 1).toInt();
  return bn ? linemanChapters[index].$1 : linemanChapters[index].$2;
}

LinemanPath linemanPath(
  LinemanProfile? profile, {
  Set<String> extraCompleted = const {},
  int? highestCompletedModule,
}) {
  final lessons = <String>{
    ...?profile?.completedLessons,
    ...extraCompleted,
  };
  final level = profile?.trainingLevel ?? 1;

  bool moduleHasProgress(int module) {
    if (level > module) return true;
    for (final raw in lessons) {
      final id = raw.toLowerCase();
      if (id.startsWith('$module-') ||
          id.startsWith('${module}_') ||
          id.startsWith('$module.')) {
        return true;
      }
    }
    return false;
  }

  var achieved = 0;
  if (highestCompletedModule != null) {
    achieved = highestCompletedModule.clamp(0, 10);
  } else {
    for (var module = 1; module <= 10; module++) {
      if (!moduleHasProgress(module)) break;
      achieved = module;
    }
  }

  final reading = profile?.readingPoints ?? 0;
  final spare = (reading - (achieved * 40)).clamp(0, 40);
  var towardNext = achieved >= 10 ? 1.0 : spare / 40;
  if (achieved < 10 && level > achieved) {
    towardNext = math.max(towardNext, 0.35);
  }

  final quiz = profile?.quizPoints ?? 0;
  final penalties = profile?.totalPenalties ?? 0;
  final battery = ((quiz / 400) - (penalties / 300)).clamp(0.08, 1.0);

  final pins = <CautionPin>[
    for (var i = 0; i < linemanChapters.length; i++)
      CautionPin(
        labelBn: linemanChapters[i].$1,
        labelEn: linemanChapters[i].$2,
        icon: linemanChapters[i].$3,
        earned: i < achieved,
      ),
  ];

  return LinemanPath(
    achieved: achieved,
    towardNext: towardNext,
    battery: battery,
    pins: pins,
  );
}
