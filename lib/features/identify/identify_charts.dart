import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chart numbers always use English digits.
String chartEnglishDigits(String value) {
  const bn = '০১২৩৪৫৬৭৮৯';
  final buf = StringBuffer();
  for (final r in value.runes) {
    final ch = String.fromCharCode(r);
    final i = bn.indexOf(ch);
    buf.write(i >= 0 ? '$i' : ch);
  }
  return buf.toString();
}

class ChartStep {
  final String title;
  final String? ok;
  final String? bad;

  const ChartStep({required this.title, this.ok, this.bad});

  factory ChartStep.fromJson(Map<String, dynamic> json) => ChartStep(
        title: chartEnglishDigits(json['title']?.toString() ?? ''),
        ok: json['ok'] == null ? null : chartEnglishDigits(json['ok'].toString()),
        bad: json['bad'] == null ? null : chartEnglishDigits(json['bad'].toString()),
      );
}

class ChartCompareSide {
  final String title;
  final List<String> points;

  const ChartCompareSide({required this.title, required this.points});

  factory ChartCompareSide.fromJson(Map<String, dynamic> json) => ChartCompareSide(
        title: chartEnglishDigits(json['title']?.toString() ?? ''),
        points: [
          for (final p in (json['points'] as List? ?? const [])) chartEnglishDigits(p.toString()),
        ],
      );
}

class ChartTable {
  final String? title;
  final List<String> headers;
  final List<List<String>> rows;
  final String? note;
  final List<String> notes;

  const ChartTable({
    this.title,
    required this.headers,
    required this.rows,
    this.note,
    this.notes = const [],
  });

  factory ChartTable.fromJson(Map<String, dynamic> json) => ChartTable(
        title: json['title'] == null ? null : chartEnglishDigits(json['title'].toString()),
        headers: [
          for (final h in (json['headers'] as List? ?? const [])) chartEnglishDigits(h.toString()),
        ],
        rows: [
          for (final row in (json['rows'] as List? ?? const []))
            [for (final c in (row as List)) chartEnglishDigits(c.toString())],
        ],
        note: json['note'] == null ? null : chartEnglishDigits(json['note'].toString()),
        notes: [
          for (final n in (json['notes'] as List? ?? const [])) chartEnglishDigits(n.toString()),
        ],
      );
}

class ChartCardBlock {
  final String title;
  final List<String> points;

  const ChartCardBlock({required this.title, required this.points});

  factory ChartCardBlock.fromJson(Map<String, dynamic> json) => ChartCardBlock(
        title: chartEnglishDigits(json['title']?.toString() ?? ''),
        points: [
          for (final p in (json['points'] as List? ?? const [])) chartEnglishDigits(p.toString()),
        ],
      );
}

class ChartSection {
  final String title;
  final String tone;
  final List<String> points;

  const ChartSection({required this.title, required this.tone, required this.points});

  factory ChartSection.fromJson(Map<String, dynamic> json) => ChartSection(
        title: chartEnglishDigits(json['title']?.toString() ?? ''),
        tone: json['tone']?.toString() ?? 'neutral',
        points: [
          for (final p in (json['points'] as List? ?? const [])) chartEnglishDigits(p.toString()),
        ],
      );
}

class ChartFigure {
  final String image;
  final String? title;
  final String? info;

  const ChartFigure({required this.image, this.title, this.info});

  factory ChartFigure.fromJson(Map<String, dynamic> json) {
    var image = json['image']?.toString() ?? '';
    if (image.startsWith('/')) image = image.substring(1);
    return ChartFigure(
      image: image,
      title: json['title'] == null ? null : chartEnglishDigits(json['title'].toString()),
      info: json['info'] == null ? null : chartEnglishDigits(json['info'].toString()),
    );
  }
}

class IdentifyChartPage {
  final String id;
  final String kind;
  final String? kicker;
  final String? intro;
  final String? tip;
  final String? warning;
  final List<ChartStep> steps;
  final ChartCompareSide? wrong;
  final ChartCompareSide? right;
  final List<ChartTable> tables;
  final List<ChartCardBlock> cards;
  final List<ChartSection> sections;
  final List<String> flow;
  final ChartFigure? figure;

  const IdentifyChartPage({
    required this.id,
    required this.kind,
    this.kicker,
    this.intro,
    this.tip,
    this.warning,
    this.steps = const [],
    this.wrong,
    this.right,
    this.tables = const [],
    this.cards = const [],
    this.sections = const [],
    this.flow = const [],
    this.figure,
  });

  factory IdentifyChartPage.fromJson(String id, Map<String, dynamic> json) {
    final compare = json['compare'] as Map<String, dynamic>?;
    return IdentifyChartPage(
      id: id,
      kind: json['kind']?.toString() ?? 'sections',
      kicker: json['kicker'] == null ? null : chartEnglishDigits(json['kicker'].toString()),
      intro: json['intro'] == null ? null : chartEnglishDigits(json['intro'].toString()),
      tip: json['tip'] == null ? null : chartEnglishDigits(json['tip'].toString()),
      warning: json['warning'] == null ? null : chartEnglishDigits(json['warning'].toString()),
      steps: [
        for (final s in (json['steps'] as List? ?? const []))
          ChartStep.fromJson(s as Map<String, dynamic>),
      ],
      wrong: compare?['wrong'] == null
          ? null
          : ChartCompareSide.fromJson(compare!['wrong'] as Map<String, dynamic>),
      right: compare?['right'] == null
          ? null
          : ChartCompareSide.fromJson(compare!['right'] as Map<String, dynamic>),
      tables: [
        for (final t in (json['tables'] as List? ?? const []))
          ChartTable.fromJson(t as Map<String, dynamic>),
      ],
      cards: [
        for (final c in (json['cards'] as List? ?? const []))
          ChartCardBlock.fromJson(c as Map<String, dynamic>),
      ],
      sections: [
        for (final s in (json['sections'] as List? ?? const []))
          ChartSection.fromJson(s as Map<String, dynamic>),
      ],
      flow: [
        for (final f in (json['flow'] as List? ?? const [])) chartEnglishDigits(f.toString()),
      ],
      figure: json['figure'] == null
          ? null
          : ChartFigure.fromJson(json['figure'] as Map<String, dynamic>),
    );
  }

  String kindLabel(bool bn) => switch (kind) {
        'howto' => bn ? 'ধাপ' : 'How-to',
        'compare' => bn ? 'তুলনা' : 'Compare',
        'table' => bn ? 'ছক' : 'Table',
        'cards' => bn ? 'কার্ড' : 'Cards',
        'sections' => bn ? 'বিভাগ' : 'Sections',
        _ => bn ? 'চার্ট' : 'Chart',
      };

  String previewLine() {
    if (kicker != null && kicker!.trim().isNotEmpty) return kicker!;
    if (intro != null && intro!.trim().isNotEmpty) return intro!;
    if (tip != null && tip!.trim().isNotEmpty) return tip!;
    return '';
  }
}

class ChartTopic {
  final IconData icon;
  final String shortBn;
  final Color accent;
  final Color soft;

  const ChartTopic({
    required this.icon,
    required this.shortBn,
    required this.accent,
    required this.soft,
  });
}

const _topics = <String, ChartTopic>{
  'Charts:হেলমেট কিভাবে পড়তে হয়': ChartTopic(
    icon: Icons.health_and_safety_rounded,
    shortBn: 'হেলমেট',
    accent: Color(0xFFEA580C),
    soft: Color(0xFFFFF7ED),
  ),
  'Charts:কোমর রশা vs হারনেস': ChartTopic(
    icon: Icons.accessibility_new_rounded,
    shortBn: 'হারনেস',
    accent: Color(0xFFE11D48),
    soft: Color(0xFFFFF1F2),
  ),
  'Charts:ডিটিআর ফিউজ রেটিং চার্ট': ChartTopic(
    icon: Icons.bolt_rounded,
    shortBn: 'ফিউজ',
    accent: Color(0xFFD97706),
    soft: Color(0xFFFFFBEB),
  ),
  'Charts:ট্রান্সফরমার কারেন্ট রেটিং চার্ট': ChartTopic(
    icon: Icons.electric_meter_rounded,
    shortBn: 'কারেন্ট',
    accent: Color(0xFF0284C7),
    soft: Color(0xFFF0F9FF),
  ),
  'Charts:নিরাপদ দূরত্বের চার্ট': ChartTopic(
    icon: Icons.straighten_rounded,
    shortBn: 'দূরত্ব',
    accent: Color(0xFF059669),
    soft: Color(0xFFECFDF5),
  ),
  'Charts:মই-এর ভাল মন্দ': ChartTopic(
    icon: Icons.stairs_rounded,
    shortBn: 'মই',
    accent: Color(0xFFEA580C),
    soft: Color(0xFFFFF7ED),
  ),
  'Charts:মই ব্যবহারের ৩-পয়েন্ট নিয়ম': ChartTopic(
    icon: Icons.filter_3_rounded,
    shortBn: '3 পয়েন্ট',
    accent: Color(0xFFE11D48),
    soft: Color(0xFFFFF1F2),
  ),
  'Charts:ফুল বডি হারনেস কিভাবে পড়তে হয়': ChartTopic(
    icon: Icons.accessibility_new_rounded,
    shortBn: 'হারনেস পরুন',
    accent: Color(0xFFEA580C),
    soft: Color(0xFFFFF7ED),
  ),
  'Charts:পিপিই কবে বদলাবেন': ChartTopic(
    icon: Icons.event_available_rounded,
    shortBn: 'পিপিই বদল',
    accent: Color(0xFF7C3AED),
    soft: Color(0xFFF5F3FF),
  ),
  'Charts:ACSR কারেন্ট বহন ক্ষমতা': ChartTopic(
    icon: Icons.cable_rounded,
    shortBn: 'ACSR',
    accent: Color(0xFF0284C7),
    soft: Color(0xFFF0F9FF),
  ),
  'Charts:কিছু পরিচিত তার ও কেবিলের ব্যবহার': ChartTopic(
    icon: Icons.cable_rounded,
    shortBn: 'তার-কেবল',
    accent: Color(0xFFD97706),
    soft: Color(0xFFFFFBEB),
  ),
  'Charts:আপনার সেফিটি গ্লাভস চিনুন': ChartTopic(
    icon: Icons.back_hand_rounded,
    shortBn: 'গ্লাভস',
    accent: Color(0xFF059669),
    soft: Color(0xFFECFDF5),
  ),
  'Charts:ডিসচার্জ রডের সঠিক ব্যবহার': ChartTopic(
    icon: Icons.flash_on_rounded,
    shortBn: 'ডিসচার্জ',
    accent: Color(0xFFE11D48),
    soft: Color(0xFFFFF1F2),
  ),
  'Charts:DTR স্মার্ট চার্ট': ChartTopic(
    icon: Icons.auto_awesome_rounded,
    shortBn: 'ডিটিআর',
    accent: Color(0xFFEA580C),
    soft: Color(0xFFFFF7ED),
  ),
  'Charts:কেবল রেটিং চার্ট': ChartTopic(
    icon: Icons.cable_rounded,
    shortBn: 'কেবল',
    accent: Color(0xFF0284C7),
    soft: Color(0xFFF0F9FF),
  ),
};

ChartTopic chartTopic(String id) =>
    _topics[id] ??
    const ChartTopic(
      icon: Icons.menu_book_rounded,
      shortBn: 'চার্ট',
      accent: Color(0xFFEA580C),
      soft: Color(0xFFFFF7ED),
    );

final identifyChartPagesProvider = FutureProvider<Map<String, IdentifyChartPage>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/identify_chart_pages.json');
  final map = jsonDecode(raw) as Map<String, dynamic>;
  return {
    for (final e in map.entries) e.key: IdentifyChartPage.fromJson(e.key, e.value as Map<String, dynamic>),
  };
});

IdentifyChartPage? chartPageOf(Map<String, IdentifyChartPage>? pages, String id) => pages?[id];

bool isChartItem(String category, String id, Map<String, IdentifyChartPage>? pages) {
  return category == 'Charts' || (pages != null && pages.containsKey(id));
}
