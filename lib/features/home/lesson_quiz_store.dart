import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import 'lesson_quiz_page.dart';

/// What a lesson quiz load produced.
enum LessonQuizStatus {
  /// Questions are ready (from memory, disk or the network).
  ready,

  /// The server says this lesson has no quiz (404 or an empty list).
  noQuiz,

  /// No copy on this phone and the download failed (offline, slow, bad reply).
  unavailable,
}

class LessonQuizLoad {
  final LessonQuizStatus status;
  final List<LessonQuizQuestion> questions;

  const LessonQuizLoad._(this.status, this.questions);

  const LessonQuizLoad.ready(List<LessonQuizQuestion> questions) : this._(LessonQuizStatus.ready, questions);
  static const noQuiz = LessonQuizLoad._(LessonQuizStatus.noQuiz, []);
  static const unavailable = LessonQuizLoad._(LessonQuizStatus.unavailable, []);

  bool get isReady => status == LessonQuizStatus.ready && questions.isNotEmpty;
}

class LessonQuizHttpResponse {
  final int statusCode;
  final String body;

  const LessonQuizHttpResponse(this.statusCode, this.body);
}

typedef LessonQuizHttpGet = Future<LessonQuizHttpResponse> Function(Uri uri);

/// Lesson quiz questions: memory, then a small disk copy, then the network.
///
/// A quiz downloaded once keeps working offline. The disk copy is refreshed
/// in the background when it is older than [refreshAfter].
class LessonQuizStore {
  LessonQuizStore({
    LessonQuizHttpGet? httpGet,
    Future<Directory> Function()? cacheRoot,
    this.refreshAfter = const Duration(days: 7),
  })  : _httpGet = httpGet ?? _defaultGet,
        _cacheRoot = cacheRoot ?? getApplicationSupportDirectory;

  /// Shared instance. Tests may replace it.
  static LessonQuizStore instance = LessonQuizStore();

  final LessonQuizHttpGet _httpGet;
  final Future<Directory> Function() _cacheRoot;
  final Duration refreshAfter;
  final Map<String, List<LessonQuizQuestion>> _memory = {};
  final Map<String, Future<LessonQuizLoad>> _inFlight = {};
  Directory? _dir;

  Future<LessonQuizLoad> load(int module, int chapter) {
    final file = lessonQuizFileName(module, chapter);
    final hot = _memory[file];
    if (hot != null) return Future.value(LessonQuizLoad.ready(hot));
    // Block body: returning the removed future from whenComplete would make
    // the load wait on itself.
    return _inFlight[file] ??= _load(file).whenComplete(() {
      _inFlight.remove(file);
    });
  }

  /// The copy already on this phone (memory, then disk) — never the network.
  /// Null when none is saved. Never throws.
  Future<List<LessonQuizQuestion>?> cachedOnly(int module, int chapter) async {
    final file = lessonQuizFileName(module, chapter);
    final hot = _memory[file];
    if (hot != null) return hot;
    final disk = await _readDisk(file);
    if (disk == null) return null;
    return _memory[file] = disk.questions;
  }

  /// Warm the cache while the lesson is being read. Never throws.
  Future<void> prefetch(int module, int chapter) async {
    try {
      await load(module, chapter);
    } catch (_) {}
  }

  Future<LessonQuizLoad> _load(String file) async {
    final disk = await _readDisk(file);
    if (disk != null) {
      _memory[file] = disk.questions;
      if (disk.stale) unawaited(_download(file).then((_) {}, onError: (_) {}));
      return LessonQuizLoad.ready(disk.questions);
    }
    return _download(file);
  }

  Future<LessonQuizLoad> _download(String file) async {
    final LessonQuizHttpResponse res;
    try {
      res = await _httpGet(Uri.parse('${AppConstants.remoteAssetOrigin}/quizzes/$file'))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      return LessonQuizLoad.unavailable;
    }
    if (res.statusCode == 404 || res.statusCode == 410) return LessonQuizLoad.noQuiz;
    if (res.statusCode != 200) return LessonQuizLoad.unavailable;
    final dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      // The site answers missing files with its HTML page, and captive Wi-Fi
      // portals do the same, so a non-JSON reply is never "no quiz".
      return LessonQuizLoad.unavailable;
    }
    if (decoded is! List) return LessonQuizLoad.unavailable;
    if (decoded.isEmpty) return LessonQuizLoad.noQuiz;
    final list = parseLessonQuiz(decoded);
    if (list.isEmpty) return LessonQuizLoad.unavailable;
    _memory[file] = list;
    await _writeDisk(file, res.body);
    return LessonQuizLoad.ready(list);
  }

  Future<Directory?> _cacheDir() async {
    if (_dir != null) return _dir;
    try {
      final root = await _cacheRoot();
      final dir = Directory('${root.path}/lesson_quiz_v1');
      if (!dir.existsSync()) await dir.create(recursive: true);
      return _dir = dir;
    } catch (_) {
      return null;
    }
  }

  Future<({List<LessonQuizQuestion> questions, bool stale})?> _readDisk(String file) async {
    try {
      final dir = await _cacheDir();
      if (dir == null) return null;
      final f = File('${dir.path}/$file');
      if (!f.existsSync()) return null;
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! List) return null;
      final list = parseLessonQuiz(decoded);
      if (list.isEmpty) return null;
      final age = DateTime.now().difference(f.lastModifiedSync());
      return (questions: list, stale: age > refreshAfter);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(String file, String body) async {
    try {
      final dir = await _cacheDir();
      if (dir == null) return;
      final tmp = File('${dir.path}/$file.part');
      await tmp.writeAsString(body, flush: true);
      await tmp.rename('${dir.path}/$file');
    } catch (_) {}
  }

  @visibleForTesting
  void clearMemory() => _memory.clear();
}

List<LessonQuizQuestion> parseLessonQuiz(List<dynamic> raw) =>
    raw.map(LessonQuizQuestion.fromJson).whereType<LessonQuizQuestion>().toList();

Future<LessonQuizHttpResponse> _defaultGet(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(uri);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return LessonQuizHttpResponse(res.statusCode, body);
  } finally {
    client.close(force: true);
  }
}
