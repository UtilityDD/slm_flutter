import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/lesson_quiz_page.dart' show LessonQuizQuestion;

// Life skills ("জীবন দক্ষতা", LS01–LS13): the owner's 13 supplementary
// modules from slm_web, copied into assets/life_skills/ (modules.json,
// lessons/, questions/, cards/, images/). They are lucky-toolbox prizes
// (lucky_toolbox.dart): invisible until won, then kept for good in
// ToolboxSave.lifeSkills and listed under "আমার জীবন দক্ষতা".

/// The 13 life-skill ids, in the web's order. A prize is always one of these.
const kLifeSkillIds = <String>[
  'supp_10_1', 'supp_10_2', 'supp_10_3', 'supp_10_4', 'supp_10_5', 'supp_10_6', 'supp_10_7',
  'supp_10_8', 'supp_10_9', 'supp_10_10', 'supp_10_11', 'supp_10_12', 'supp_10_13',
];

const kLifeSkillsModulesAsset = 'assets/life_skills/modules.json';

@immutable
class LifeSkillModule {
  const LifeSkillModule({
    required this.id,
    required this.code,
    required this.titleBn,
    required this.descriptionBn,
    required this.cardAsset,
    required this.lessonAsset,
    required this.questionsAsset,
    required this.audioUrl,
    this.icon = '',
  });

  final String id;

  /// LS01 … LS13.
  final String code;
  final String titleBn;
  final String descriptionBn;
  final String cardAsset;
  final String lessonAsset;
  final String questionsAsset;

  /// Streamed once, then cached on the phone (life_skill_audio.dart).
  final String audioUrl;
  final String icon;

  factory LifeSkillModule.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final n = id.split('_').last;
    return LifeSkillModule(
      id: id,
      code: j['lesson_code'] as String? ?? '',
      titleBn: j['title_bn'] as String? ?? '',
      descriptionBn: j['description_bn'] as String? ?? '',
      cardAsset: j['image_url'] as String? ?? '',
      lessonAsset: j['manuscript_url'] as String? ?? 'assets/life_skills/lessons/lesson_10_$n.json',
      questionsAsset: j['questions_url'] as String? ?? 'assets/life_skills/questions/questions_supp_10_$n.json',
      audioUrl: (j['audio_url_bn'] ?? j['audio_url_en'] ?? '') as String,
      icon: j['icon'] as String? ?? '',
    );
  }
}

@immutable
class LifeSkillPoint {
  const LifeSkillPoint({
    required this.name,
    required this.image,
    required this.caption,
    required this.specifications,
    required this.importance,
    required this.dailyCheck,
  });

  final String name;
  final String image;
  final String caption;
  final String specifications;
  final String importance;
  final String dailyCheck;
}

@immutable
class LifeSkillSection {
  const LifeSkillSection(this.title, this.points);

  final String title;
  final List<LifeSkillPoint> points;
}

@immutable
class LifeSkillMyth {
  const LifeSkillMyth(this.myth, this.reality);

  final String myth;
  final String reality;
}

@immutable
class LifeSkillLesson {
  const LifeSkillLesson({
    required this.title,
    required this.briefing,
    required this.sections,
    required this.proTipTitle,
    required this.proTips,
    required this.mythTitle,
    required this.mythImage,
    required this.myths,
    required this.moreTitle,
    required this.moreFacts,
  });

  final String title;
  final String briefing;
  final List<LifeSkillSection> sections;
  final String proTipTitle;
  final List<String> proTips;
  final String mythTitle;
  final String mythImage;
  final List<LifeSkillMyth> myths;

  /// "advanced_section": extra facts (title, content).
  final String moreTitle;
  final List<(String, String)> moreFacts;

  factory LifeSkillLesson.fromJson(Map<String, dynamic> j) {
    String s(Object? v) => v is String ? v : '';
    Map<String, dynamic> m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
    List<Object?> l(Object? v) => v is List ? v : const [];
    final pro = m(j['pro_tip']);
    final myth = m(j['myth_buster']);
    final adv = m(j['advanced_section']);
    return LifeSkillLesson(
      title: s(j['level_title']),
      briefing: s(j['mission_briefing']),
      sections: [
        for (final raw in l(j['sections']))
          LifeSkillSection(s(m(raw)['title']), [
            for (final p in l(m(raw)['points']))
              LifeSkillPoint(
                name: s(m(p)['item_name']),
                image: s(m(p)['image_name']),
                caption: s(m(p)['image_caption']),
                specifications: s(m(p)['specifications']),
                importance: s(m(p)['importance']),
                dailyCheck: s(m(p)['daily_check']),
              ),
          ]),
      ],
      proTipTitle: s(pro['title']),
      proTips: [for (final c in l(pro['content'])) s(c)],
      mythTitle: s(myth['title']),
      mythImage: s(myth['image_name']),
      myths: [for (final x in l(myth['myths'])) LifeSkillMyth(s(m(x)['myth']), s(m(x)['reality']))],
      moreTitle: s(adv['title']),
      moreFacts: [for (final f in l(adv['facts'])) (s(m(f)['title']), s(m(f)['content']))],
    );
  }
}

/// Reads the bundled life-skill files once and keeps them (they are small).
class LifeSkillsRepo {
  LifeSkillsRepo({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static LifeSkillsRepo instance = LifeSkillsRepo();

  final AssetBundle _bundle;
  Future<List<LifeSkillModule>>? _modules;
  final _lessons = <String, Future<LifeSkillLesson?>>{};
  final _questions = <String, Future<List<LessonQuizQuestion>>>{};

  Future<List<LifeSkillModule>> modules() => _modules ??= () async {
        try {
          final raw = jsonDecode(await _bundle.loadString(kLifeSkillsModulesAsset));
          return [
            for (final m in raw as List)
              if (m is Map) LifeSkillModule.fromJson(Map<String, dynamic>.from(m)),
          ];
        } catch (_) {
          _modules = null;
          return const <LifeSkillModule>[];
        }
      }();

  Future<LifeSkillModule?> module(String id) async {
    for (final m in await modules()) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<LifeSkillLesson?> lesson(String id) => _lessons[id] ??= () async {
        final m = await module(id);
        if (m == null) return null;
        try {
          return LifeSkillLesson.fromJson(
            Map<String, dynamic>.from(jsonDecode(await _bundle.loadString(m.lessonAsset)) as Map),
          );
        } catch (_) {
          _lessons.remove(id);
          return null;
        }
      }();

  /// A won life skill's quiz (answers are in the file: an offline source).
  Future<List<LessonQuizQuestion>> questions(String id) => _questions[id] ??= () async {
        final m = await module(id);
        if (m == null) return const <LessonQuizQuestion>[];
        try {
          final raw = jsonDecode(await _bundle.loadString(m.questionsAsset)) as List;
          return [
            for (final q in raw) ?LessonQuizQuestion.fromJson(q),
          ];
        } catch (_) {
          _questions.remove(id);
          return const <LessonQuizQuestion>[];
        }
      }();
}

final lifeSkillModulesProvider = FutureProvider<List<LifeSkillModule>>((ref) => LifeSkillsRepo.instance.modules());

abstract final class LifeSkillLines {
  static const menu = 'আমার জীবন দক্ষতা';
  static const listSub = 'টুলবক্স থেকে জেতা দক্ষতা — যখন খুশি পড়ুন ও শুনুন।';
  static const won = 'জীবন দক্ষতা পেলেন!';
  static const prize = 'জীবন দক্ষতা';
  static const proTip = 'কাজের টিপস';
  static const myth = 'ভুল ধারণা';
  static const reality = 'আসলে';
  static const dailyCheck = 'আজকের যাচাই';
  static const listen = 'শুনুন';
  static const pause = 'থামান';
  static const offlineNote = 'প্রথমবার শুনতে ইন্টারনেট লাগবে। একবার পুরোটা শুনলে পরে অফলাইনেও চলবে।';
  static const savedNote = 'অডিও ফোনে রাখা আছে — অফলাইনেও চলবে।';
  static const audioFailed = 'এখন অডিও চালানো গেল না। ইন্টারনেট চালু করে আবার চেষ্টা করুন।';
  static const loadFailed = 'দক্ষতাটি খোলা গেল না। আবার চেষ্টা করুন।';
  static const retry = 'আবার চেষ্টা';
}
