import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

// A life skill's narration (life_skill_NN.wav on GitHub raw) is streamed the
// first time. After one full play it is saved in app storage, so later plays
// work offline. The WAVs are never bundled in the APK.

/// Downloads [url] fully (throws on any failure or non-200).
typedef LifeSkillAudioFetch = Future<List<int>> Function(Uri url);

class LifeSkillAudioCache {
  LifeSkillAudioCache({Future<Directory> Function()? root, LifeSkillAudioFetch? fetch})
      : _root = root ?? getApplicationSupportDirectory,
        _fetch = fetch ?? _httpFetch;

  static LifeSkillAudioCache instance = LifeSkillAudioCache();

  static const folder = 'life_skills_audio';

  final Future<Directory> Function() _root;
  final LifeSkillAudioFetch _fetch;
  final _saving = <String, Future<bool>>{};

  /// `life_skill_01.wav` from the URL; null when the URL has no usable name.
  static String? fileNameFor(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.pathSegments.isEmpty) return null;
    final name = uri.pathSegments.last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    if (name.isEmpty || name.startsWith('.')) return null;
    return name;
  }

  /// Where [url]'s audio lives on the phone (it may not exist yet).
  Future<File?> fileFor(String url) async {
    final name = fileNameFor(url);
    if (name == null) return null;
    final root = await _root();
    return File('${root.path}${Platform.pathSeparator}$folder${Platform.pathSeparator}$name');
  }

  /// The saved file, or null when it has not been saved yet.
  Future<File?> cached(String url) async {
    try {
      final f = await fileFor(url);
      if (f != null && await f.exists() && await f.length() > 0) return f;
    } catch (_) {}
    return null;
  }

  /// Called after a streamed play reached the end: downloads the file once
  /// and saves it (a temp file renamed at the end, so a cut download never
  /// leaves a broken file). True when the audio is now saved.
  Future<bool> saveAfterFullPlay(String url) {
    return _saving[url] ??= () async {
      try {
        if (await cached(url) != null) return true;
        final f = await fileFor(url);
        if (f == null) return false;
        final bytes = await _fetch(Uri.parse(url));
        if (bytes.isEmpty) return false;
        await f.parent.create(recursive: true);
        final part = File('${f.path}.part');
        await part.writeAsBytes(bytes, flush: true);
        await part.rename(f.path);
        return true;
      } catch (_) {
        return false;
      } finally {
        unawaited(Future<void>.microtask(() => _saving.remove(url)));
      }
    }();
  }

  static Future<List<int>> _httpFetch(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(url);
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw HttpException('status ${res.statusCode}', uri: url);
      final out = BytesBuilder(copy: false);
      await for (final chunk in res.timeout(const Duration(seconds: 30))) {
        out.add(chunk);
      }
      return out.takeBytes();
    } finally {
      client.close(force: true);
    }
  }
}
