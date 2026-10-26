import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryItem {
  final String id;
  final String category;
  final String nameBn;
  final String functionBn;
  final String guideBn;
  final String price;
  final List<String> images;
  final List<String> relatedIds;

  const LibraryItem({
    required this.id,
    required this.category,
    required this.nameBn,
    required this.functionBn,
    required this.guideBn,
    required this.price,
    required this.images,
    this.relatedIds = const [],
  });

  bool get hasPhoto => images.isNotEmpty;

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return LibraryItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Others',
      nameBn: json['name_bn']?.toString() ?? '',
      functionBn: json['function_bn']?.toString() ?? '',
      guideBn: json['guide_bn']?.toString() ?? '',
      price: json['approx_price_inr']?.toString() ?? '',
      images: images,
      relatedIds: json['related_items'] is List
          ? (json['related_items'] as List)
              .map((e) => e is Map ? e['id']?.toString() ?? '' : e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

/// Known groups first, then any new category found in the data.
List<String> orderedCategories(Iterable<LibraryItem> items) {
  final present = <String>{for (final item in items) item.category};
  return [
    for (final id in categoryOrder)
      if (present.contains(id)) id,
    ...(present.where((id) => !categoryOrder.contains(id)).toList()..sort()),
  ];
}

const categoryOrder = [
  'PPE',
  'Tools',
  'Insulators',
  'AB Cable Items',
  'Others',
  'Charts',
];

String categoryLabel(String id, bool bn) {
  const labels = {
    'PPE': ('পিপিই', 'PPE'),
    'Tools': ('টুল', 'Tools'),
    'Insulators': ('ইনসুলেটর', 'Insulators'),
    'AB Cable Items': ('এবি কেবল', 'AB cable'),
    'Others': ('অন্যান্য', 'Others'),
    'Charts': ('চার্ট', 'Charts'),
  };
  final row = labels[id];
  if (row == null) return id;
  return bn ? row.$1 : row.$2;
}

final libraryCatalogProvider = FutureProvider<List<LibraryItem>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/safety_library.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((row) => LibraryItem.fromJson(row as Map<String, dynamic>))
      .where((item) => item.nameBn.trim().isNotEmpty)
      .toList();
});

class IdentifyChoice {
  final String id;
  final String nameBn;
  final String image;

  const IdentifyChoice({required this.id, required this.nameBn, required this.image});
}

class ChartFact {
  final String id;
  final String answer;
  final List<String> asks;
  final List<String> distractors;

  const ChartFact({
    required this.id,
    required this.answer,
    required this.asks,
    required this.distractors,
  });

  factory ChartFact.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? raw) =>
        raw is List ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : <String>[];
    return ChartFact(
      id: json['id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      asks: strings(json['asks']),
      distractors: strings(json['distractors']),
    );
  }
}

final chartFactsProvider = FutureProvider<List<ChartFact>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/identify_chart_facts.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((row) => ChartFact.fromJson(row as Map<String, dynamic>))
      .where((fact) => fact.asks.isNotEmpty && fact.distractors.length >= 3)
      .toList();
});

/// One practice question, matching the web Identify game.
/// [photoChoices] false = one photo, four names. True = a 2×2 photo board.
/// [textChoices] is the chart quiz: a written question and four written answers.
class IdentifyQuestion {
  final String id;
  final String mode;
  final String prompt;
  final String detail;
  final String highlight;
  final String heroImage;
  final bool photoChoices;
  final bool textChoices;
  final List<IdentifyChoice> choices;
  final String correctId;

  const IdentifyQuestion({
    required this.id,
    required this.mode,
    required this.prompt,
    this.detail = '',
    required this.highlight,
    required this.heroImage,
    required this.photoChoices,
    this.textChoices = false,
    required this.choices,
    required this.correctId,
  });
}

const _practiceModes = ['name', 'grid', 'clue', 'odd', 'which'];

IdentifyQuestion? buildNextIdentifyQuestion(
  List<LibraryItem> items, {
  String? avoidId,
  List<String> recentModes = const [],
  List<ChartFact> charts = const [],
}) {
  final pool = items.where((item) => item.hasPhoto && item.nameBn.trim().isNotEmpty).toList();
  if (pool.length < 4) return null;
  final mode = _nextMode(pool, recentModes, charts);
  return switch (mode) {
    'grid' => _nameOnBoard(pool, avoidId),
    'clue' => _clueBoard(pool, avoidId) ?? _nameOnBoard(pool, avoidId),
    'odd' => _oddBoard(pool, avoidId) ?? _nameOnBoard(pool, avoidId),
    'which' => _whichBoard(pool, avoidId) ?? _nameOnBoard(pool, avoidId),
    'chart' => _chartQuestion(charts, avoidId) ?? _nameQuestion(pool, avoidId),
    _ => _nameQuestion(pool, avoidId),
  };
}

String _nextMode(List<LibraryItem> pool, List<String> recent, List<ChartFact> charts) {
  final last = recent.isEmpty ? null : recent.last;
  final prev = recent.length < 2 ? null : recent[recent.length - 2];
  final random = Random();
  var mode = (last != null && last == prev)
      ? (_practiceModes.where((m) => m != last).toList()..shuffle(random)).first
      : _practiceModes[random.nextInt(_practiceModes.length)];
  final clueReady = pool.where((item) => item.functionBn.trim().length >= 10 || item.guideBn.trim().length >= 10).length >= 4;
  if (mode == 'clue' && !clueReady) mode = last == 'grid' ? 'name' : 'grid';
  if ((mode == 'odd' || mode == 'which') && !_familyReady(pool)) {
    mode = last == 'grid' ? 'name' : 'grid';
  }
  if (charts.length >= 4 && last != 'chart' && random.nextDouble() < 0.2) return 'chart';
  return mode;
}

bool _familyReady(List<LibraryItem> pool) {
  const families = ['PPE', 'Tools', 'Insulators'];
  return families.any((family) {
    final mates = pool.where((item) => item.category == family).length;
    final others = pool.length - mates;
    return mates >= 3 && others >= 3;
  });
}

IdentifyQuestion? _nameQuestion(List<LibraryItem> pool, String? avoidId) {
  final item = _pick(pool, avoidId);
  if (item == null) return null;
  final choices = _nameChoices(item, pool);
  if (choices.length < 4) return null;
  return IdentifyQuestion(
    id: item.id,
    mode: 'name',
    prompt: 'নাম কী?',
    highlight: '',
    heroImage: _imageOf(item),
    photoChoices: false,
    choices: choices,
    correctId: item.id,
  );
}

IdentifyQuestion? _nameOnBoard(List<LibraryItem> pool, String? avoidId) {
  final item = _pick(pool, avoidId);
  if (item == null) return null;
  final choices = _photoChoices(item, pool);
  if (choices.length < 4) return null;
  return IdentifyQuestion(
    id: item.id,
    mode: 'grid',
    prompt: 'কোনটা',
    highlight: item.nameBn,
    heroImage: '',
    photoChoices: true,
    choices: choices,
    correctId: item.id,
  );
}

IdentifyQuestion? _clueBoard(List<LibraryItem> pool, String? avoidId) {
  final withClue = pool.where((item) => _clue(item).length >= 10).toList();
  final item = _pick(withClue.isEmpty ? pool : withClue, avoidId);
  if (item == null) return null;
  final choices = _photoChoices(item, pool);
  if (choices.length < 4) return null;
  return IdentifyQuestion(
    id: item.id,
    mode: 'clue',
    prompt: _clueAsk(item.category),
    detail: _clue(item),
    highlight: '',
    heroImage: '',
    photoChoices: true,
    choices: choices,
    correctId: item.id,
  );
}

IdentifyQuestion? _oddBoard(List<LibraryItem> pool, String? avoidId) {
  final built = _familySplit(pool, avoidId, oddOut: true);
  if (built == null) return null;
  return IdentifyQuestion(
    id: built.correct.id,
    mode: 'odd',
    prompt: _familyAsk(built.family, odd: true),
    highlight: '',
    heroImage: '',
    photoChoices: true,
    choices: built.choices,
    correctId: built.correct.id,
  );
}

IdentifyQuestion? _whichBoard(List<LibraryItem> pool, String? avoidId) {
  final built = _familySplit(pool, avoidId, oddOut: false);
  if (built == null) return null;
  return IdentifyQuestion(
    id: built.correct.id,
    mode: 'which',
    prompt: _familyAsk(built.family, odd: false),
    highlight: '',
    heroImage: '',
    photoChoices: true,
    choices: built.choices,
    correctId: built.correct.id,
  );
}

class _FamilyPick {
  final String family;
  final LibraryItem correct;
  final List<IdentifyChoice> choices;
  const _FamilyPick(this.family, this.correct, this.choices);
}

_FamilyPick? _familySplit(List<LibraryItem> pool, String? avoidId, {required bool oddOut}) {
  const families = ['PPE', 'Tools', 'Insulators'];
  final random = Random();
  final viable = families.where((family) {
    final mates = pool.where((item) => item.category == family).length;
    return mates >= 3 && pool.length - mates >= 3;
  }).toList();
  if (viable.isEmpty) return null;
  final family = viable[random.nextInt(viable.length)];
  final mates = pool.where((item) => item.category == family).toList()..shuffle(random);
  var others = pool.where((item) => item.category != family).toList()..shuffle(random);
  if (avoidId != null) {
    final filtered = others.where((item) => item.id != avoidId).toList();
    if (filtered.isNotEmpty) others = filtered;
  }
  final LibraryItem correct;
  final List<LibraryItem> board;
  if (oddOut) {
    correct = others.first;
    board = [correct, ...mates.take(3)];
  } else {
    correct = mates.firstWhere((item) => item.id != avoidId, orElse: () => mates.first);
    board = [correct, ...others.take(3)];
  }
  board.shuffle(random);
  if (board.length < 4) return null;
  return _FamilyPick(
    family,
    correct,
    board.map((item) => IdentifyChoice(id: item.id, nameBn: item.nameBn, image: _imageOf(item))).toList(),
  );
}

LibraryItem? _pick(List<LibraryItem> pool, String? avoidId) {
  if (pool.isEmpty) return null;
  final random = Random();
  final candidates = avoidId == null ? pool : pool.where((item) => item.id != avoidId).toList();
  final source = candidates.isEmpty ? pool : candidates;
  return source[random.nextInt(source.length)];
}

List<IdentifyChoice> _nameChoices(LibraryItem item, List<LibraryItem> pool) {
  final random = Random();
  final same = pool.where((other) => other.id != item.id && other.category == item.category).toList()..shuffle(random);
  final rest = pool.where((other) => other.id != item.id && other.category != item.category).toList()..shuffle(random);
  final picked = <LibraryItem>[item];
  for (final other in [...same, ...rest]) {
    if (picked.length >= 4) break;
    if (picked.every((row) => row.nameBn != other.nameBn)) picked.add(other);
  }
  picked.shuffle(random);
  return picked.map((row) => IdentifyChoice(id: row.id, nameBn: row.nameBn, image: _imageOf(row))).toList();
}

String _imageOf(LibraryItem item) => item.images.isEmpty ? '' : item.images.first;

List<IdentifyChoice> _photoChoices(LibraryItem item, List<LibraryItem> pool) {
  final random = Random();
  final others = pool.where((other) => other.id != item.id).toList()..shuffle(random);
  final board = [item, ...others.take(3)]..shuffle(random);
  return board.map((row) => IdentifyChoice(id: row.id, nameBn: row.nameBn, image: _imageOf(row))).toList();
}

String _clue(LibraryItem item) {
  if (item.functionBn.trim().length >= 10) return item.functionBn.trim();
  return item.guideBn.trim();
}

String _clueAsk(String category) {
  return switch (category) {
    'PPE' => 'নিচের বর্ণনা কোন পিপিইকে চেনা যায়?',
    'Tools' => 'নিচের বর্ণনা কোন টুল বা মেশিনকে চেনা যায়?',
    'Insulators' => 'নিচের বর্ণনা কোন ইনসুলেটরকে চেনা যায়?',
    _ => 'নিচের বর্ণনা কোন আইটেমকে চেনা যায়?',
  };
}

String _familyAsk(String family, {required bool odd}) {
  final label = switch (family) {
    'PPE' => 'PPE',
    'Tools' => 'টুল বা মেশিন',
    'Insulators' => 'ইনসুলেটর',
    _ => 'এই দল',
  };
  return odd ? 'কোনটা $label নয়?' : 'কোনটা $label?';
}

IdentifyQuestion? _chartQuestion(List<ChartFact> charts, String? avoidId) {
  if (charts.length < 4) return null;
  final random = Random();
  final candidates = avoidId == null ? charts : charts.where((fact) => fact.id != avoidId).toList();
  final source = candidates.isEmpty ? charts : candidates;
  final fact = source[random.nextInt(source.length)];
  if (fact.asks.isEmpty) return null;
  final wrong = [...fact.distractors]..shuffle(random);
  final labels = [fact.answer, ...wrong.take(3)];
  if (labels.length < 4) return null;
  labels.shuffle(random);
  return IdentifyQuestion(
    id: fact.id,
    mode: 'chart',
    prompt: fact.asks[random.nextInt(fact.asks.length)],
    highlight: '',
    heroImage: '',
    photoChoices: false,
    textChoices: true,
    choices: [
      for (final label in labels) IdentifyChoice(id: label, nameBn: label, image: ''),
    ],
    correctId: fact.answer,
  );
}

class IdentifyStats {
  final int lifeCorrect;
  final int lifeTotal;
  final int bestPercent;

  const IdentifyStats({this.lifeCorrect = 0, this.lifeTotal = 0, this.bestPercent = 0});

  int get percent => lifeTotal == 0 ? 0 : ((lifeCorrect * 100) / lifeTotal).round();
}

class IdentifyStatsNotifier extends Notifier<IdentifyStats> {
  static const _correctKey = 'identify_life_correct_v1';
  static const _totalKey = 'identify_life_total_v1';
  static const _bestKey = 'identify_best_percent_v1';

  @override
  IdentifyStats build() {
    _load();
    return const IdentifyStats();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = IdentifyStats(
      lifeCorrect: prefs.getInt(_correctKey) ?? 0,
      lifeTotal: prefs.getInt(_totalKey) ?? 0,
      bestPercent: prefs.getInt(_bestKey) ?? 0,
    );
  }

  Future<void> recordAnswer(bool correct) async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_totalKey) ?? 0) + 1;
    final right = (prefs.getInt(_correctKey) ?? 0) + (correct ? 1 : 0);
    final percent = ((right * 100) / total).round();
    final best = max(prefs.getInt(_bestKey) ?? 0, percent);
    await prefs.setInt(_totalKey, total);
    await prefs.setInt(_correctKey, right);
    await prefs.setInt(_bestKey, best);
    state = IdentifyStats(lifeCorrect: right, lifeTotal: total, bestPercent: best);
  }
}

final identifyStatsProvider = NotifierProvider<IdentifyStatsNotifier, IdentifyStats>(IdentifyStatsNotifier.new);
