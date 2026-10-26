import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Life Skill always shows Western digits (0–9), even in Bengali copy.
String lsDigits(String raw) {
  const map = {
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
  };
  if (raw.isEmpty) return raw;
  final out = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    out.write(map[ch] ?? ch);
  }
  return out.toString();
}

class LifeSkillModule {
  final String id;
  final String code;
  final String number;
  final String titleBn;
  final String titleEn;
  final String descriptionBn;
  final String descriptionEn;
  final String duration;
  final String category;
  final String highlightsBn;
  final String highlightsEn;
  final String trustedBn;
  final String trustedEn;
  final String manuscriptUrl;
  final String audioUrlEn;
  final String audioUrlBn;

  const LifeSkillModule({
    required this.id,
    required this.code,
    required this.number,
    required this.titleBn,
    required this.titleEn,
    required this.descriptionBn,
    required this.descriptionEn,
    required this.duration,
    required this.category,
    required this.highlightsBn,
    required this.highlightsEn,
    required this.trustedBn,
    required this.trustedEn,
    required this.manuscriptUrl,
    required this.audioUrlEn,
    required this.audioUrlBn,
  });

  String title(bool bn) => lsDigits(bn ? titleBn : titleEn);
  String description(bool bn) => lsDigits(bn ? descriptionBn : descriptionEn);
  String highlights(bool bn) => lsDigits(bn ? highlightsBn : highlightsEn);
  String trusted(bool bn) => lsDigits(bn ? trustedBn : trustedEn);
  String durationLabel() => lsDigits(duration);

  String audioUrl(bool bn) {
    final pick = bn ? audioUrlBn : audioUrlEn;
    if (pick.trim().isNotEmpty) return pick.trim();
    return (bn ? audioUrlEn : audioUrlBn).trim();
  }

  bool get hasAudio => audioUrlEn.trim().isNotEmpty || audioUrlBn.trim().isNotEmpty;

  String? get manuscriptAsset {
    final name = manuscriptUrl.split('/').last.trim();
    if (name.isEmpty || !name.endsWith('.json')) return null;
    return 'assets/data/life_skill/$name';
  }

  factory LifeSkillModule.fromJson(Map<String, dynamic> json) {
    return LifeSkillModule(
      id: json['id']?.toString() ?? '',
      code: json['lesson_code']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      titleBn: json['title_bn']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      descriptionBn: json['description_bn']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      category: json['category']?.toString() ?? 'life',
      highlightsBn: json['highlights_bn']?.toString() ?? '',
      highlightsEn: json['highlights_en']?.toString() ?? '',
      trustedBn: json['trusted_blurb_bn']?.toString() ?? '',
      trustedEn: json['trusted_blurb_en']?.toString() ?? '',
      manuscriptUrl: json['manuscript_url']?.toString() ?? '',
      audioUrlEn: json['audio_url_en']?.toString() ?? '',
      audioUrlBn: json['audio_url_bn']?.toString() ?? '',
    );
  }
}

class LifeSkillTone {
  final Color accent;
  final Color soft;
  final IconData icon;

  const LifeSkillTone(this.accent, this.soft, this.icon);
}

LifeSkillTone lifeSkillTone(String category) {
  return switch (category) {
    'mental' => const LifeSkillTone(Color(0xFF0F766E), Color(0xFFCCFBF1), Icons.psychology_alt_rounded),
    'financial' => const LifeSkillTone(Color(0xFFB45309), Color(0xFFFEF3C7), Icons.savings_rounded),
    'digital' => const LifeSkillTone(Color(0xFF1D4ED8), Color(0xFFDBEAFE), Icons.smartphone_rounded),
    'social' => const LifeSkillTone(Color(0xFF7C3AED), Color(0xFFEDE9FE), Icons.handshake_rounded),
    'health' || 'physical' => const LifeSkillTone(Color(0xFFBE123C), Color(0xFFFFE4E6), Icons.favorite_rounded),
    'family' => const LifeSkillTone(Color(0xFFC2410C), Color(0xFFFFEDD5), Icons.home_rounded),
    _ => const LifeSkillTone(Color(0xFF047857), Color(0xFFD1FAE5), Icons.star_rounded),
  };
}

final lifeSkillModulesProvider = FutureProvider<List<LifeSkillModule>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/supplementary_modules.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list.map((row) => LifeSkillModule.fromJson(row as Map<String, dynamic>)).toList();
});

class LifeSkillPoint {
  final String name;
  final String caption;
  final String specs;
  final String importance;
  final String dailyCheck;

  const LifeSkillPoint({
    required this.name,
    required this.caption,
    required this.specs,
    required this.importance,
    required this.dailyCheck,
  });

  factory LifeSkillPoint.fromJson(Map<String, dynamic> json) {
    return LifeSkillPoint(
      name: json['item_name']?.toString() ?? '',
      caption: json['image_caption']?.toString() ?? '',
      specs: json['specifications']?.toString() ?? '',
      importance: json['importance']?.toString() ?? '',
      dailyCheck: json['daily_check']?.toString() ?? '',
    );
  }
}

class LifeSkillSection {
  final String title;
  final List<LifeSkillPoint> points;

  const LifeSkillSection({required this.title, required this.points});

  factory LifeSkillSection.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    return LifeSkillSection(
      title: json['title']?.toString() ?? '',
      points: raw is List
          ? raw.map((e) => LifeSkillPoint.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }
}

class LifeSkillMyth {
  final String myth;
  final String reality;

  const LifeSkillMyth({required this.myth, required this.reality});

  factory LifeSkillMyth.fromJson(Map<String, dynamic> json) {
    return LifeSkillMyth(
      myth: json['myth']?.toString() ?? '',
      reality: json['reality']?.toString() ?? '',
    );
  }
}

class LifeSkillManuscript {
  final String title;
  final String briefing;
  final List<LifeSkillSection> sections;
  final String tipTitle;
  final List<String> tips;
  final String mythTitle;
  final List<LifeSkillMyth> myths;
  final String helpline;

  const LifeSkillManuscript({
    required this.title,
    required this.briefing,
    required this.sections,
    required this.tipTitle,
    required this.tips,
    required this.mythTitle,
    required this.myths,
    required this.helpline,
  });

  factory LifeSkillManuscript.fromJson(Map<String, dynamic> json) {
    final tip = json['pro_tip'];
    final myth = json['myth_buster'];
    final advanced = json['advanced_section'];
    var helpline = '';
    if (advanced is Map && advanced['facts'] is List && (advanced['facts'] as List).isNotEmpty) {
      final first = (advanced['facts'] as List).first;
      if (first is Map) {
        final title = first['title']?.toString() ?? '';
        final content = first['content']?.toString() ?? '';
        helpline = [title, content].where((e) => e.trim().isNotEmpty).join('\n');
      }
    }
    return LifeSkillManuscript(
      title: json['level_title']?.toString() ?? '',
      briefing: json['mission_briefing']?.toString() ?? '',
      sections: json['sections'] is List
          ? (json['sections'] as List)
              .map((e) => LifeSkillSection.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      tipTitle: tip is Map ? tip['title']?.toString() ?? '' : '',
      tips: tip is Map && tip['content'] is List
          ? (tip['content'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      mythTitle: myth is Map ? myth['title']?.toString() ?? '' : '',
      myths: myth is Map && myth['myths'] is List
          ? (myth['myths'] as List).map((e) => LifeSkillMyth.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      helpline: helpline,
    );
  }
}

Future<LifeSkillManuscript?> loadLifeSkillManuscript(String? asset) async {
  if (asset == null || asset.isEmpty) return null;
  try {
    final raw = await rootBundle.loadString(asset);
    return LifeSkillManuscript.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (e, st) {
    debugPrint('LifeSkill manuscript failed ($asset): $e\n$st');
    return null;
  }
}
