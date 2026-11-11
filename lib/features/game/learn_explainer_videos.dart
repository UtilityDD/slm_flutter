/// YouTube explainer clips before each Learn board (immersive gate).
///
/// Fill [youtubeIdByLesson] as videos go live. A null / missing entry means
/// Learn opens straight to the board (today's behaviour). Prefer the 11-char
/// video id; full `youtu.be` / `watch?v=` URLs are also accepted.
library;

/// Catalog of Learn explainer videos keyed by dotted [lessonId] (`1.1`, `2.3`…).
abstract final class LearnExplainerVideos {
  /// Video id (or full URL) per lesson. Null = not uploaded yet — skip the gate.
  static const Map<String, String?> youtubeIdByLesson = {
    // Module 1
    '1.1': 'gm8u-yXIbZs', // https://youtu.be/gm8u-yXIbZs
    '1.2': null,
    '1.3': null,
    '1.4': null,
    '1.5': null,
    '1.6': null,
    '1.7': null,
    '1.8': null,
    '1.9': null,
    '1.10': null,
    // Module 2 — slots ready
    '2.1': null,
    '2.2': null,
    '2.3': null,
    '2.4': null,
    '2.5': null,
    '2.6': null,
    '2.7': null,
    '2.8': null,
    '2.9': null,
    '2.10': null,
  };

  /// Resolved 11-char YouTube id, or null when this lesson has no clip yet.
  static String? youtubeIdFor(String lessonId) {
    final raw = youtubeIdByLesson[lessonId];
    if (raw == null || raw.trim().isEmpty) return null;
    return parseVideoId(raw);
  }

  /// True when [lessonId] should open the guide → video → guide gate.
  static bool hasVideo(String lessonId) => youtubeIdFor(lessonId) != null;

  /// Accepts an id or a full YouTube URL.
  static String? parseVideoId(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (RegExp(r'^[\w-]{11}$').hasMatch(s)) return s;
    final m = RegExp(
      r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/)|youtube\.com/live/)([\w-]{11})',
    ).firstMatch(s);
    return m?.group(1);
  }
}
