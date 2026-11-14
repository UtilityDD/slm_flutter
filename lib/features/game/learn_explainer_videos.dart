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
    '1.2': 'oLe4ty2R7vw', // https://youtu.be/oLe4ty2R7vw
    '1.3': 'O1m6peWzy78', // https://youtu.be/O1m6peWzy78
    '1.4': null,
    '1.5': 'qG6RnvDMtH0', // https://youtu.be/qG6RnvDMtH0
    '1.6': 'lzzXwxMIGKc', // https://youtu.be/lzzXwxMIGKc
    '1.7': 'Qy8a10TGmSI', // https://youtu.be/Qy8a10TGmSI
    '1.8': '3dSk9u-LXwE', // https://youtu.be/3dSk9u-LXwE
    '1.9': '1sO6GLJzXg0', // https://youtu.be/1sO6GLJzXg0
    '1.10': 'CoM3UMk1JmU', // https://youtu.be/CoM3UMk1JmU
    // Module 2 — slots ready
    '2.1': 'aTfN6AS-r60', // https://youtu.be/aTfN6AS-r60
    '2.2': null,
    '2.3': null,
    '2.4': 'l12dqd18jPU', // https://youtu.be/l12dqd18jPU
    '2.5': null,
    '2.6': 'q15N-oY4YPM', // https://youtu.be/q15N-oY4YPM
    '2.7': null,
    '2.8': null,
    '2.9': null,
    '2.10': null,
    // Module 3 — slots ready
    '3.1': 'miCSTQCwu6k', // https://youtu.be/miCSTQCwu6k
    '3.2': 'PPPdRSFZTQs', // https://youtu.be/PPPdRSFZTQs
    '3.3': 'P51jMRqxTfo', // https://youtu.be/P51jMRqxTfo
    '3.4': 'Y2DGQS6_iJg', // https://youtu.be/Y2DGQS6_iJg
    '3.5': 'Rs_OuusDJh8', // https://youtu.be/Rs_OuusDJh8
    '3.6': 'WK5NjNRO3Jc', // https://youtu.be/WK5NjNRO3Jc
    '3.7': '2tTH2XFZuYk', // https://youtu.be/2tTH2XFZuYk
    '3.8': 'takpn7BxNVQ', // https://youtu.be/takpn7BxNVQ
    '3.9': 'ir6lTayis0o', // https://youtu.be/ir6lTayis0o
    '3.10': 'lzgYwf1rPQU', // https://youtu.be/lzgYwf1rPQU
    // Module 4 — slots ready
    '4.1': 'PgRSNSSv7aw', // https://youtu.be/PgRSNSSv7aw
    '4.2': 'T3FVohnGVXs', // https://youtu.be/T3FVohnGVXs
    '4.3': 'fhIIKKiW2Cs', // https://youtu.be/fhIIKKiW2Cs
    '4.4': 'nMb4L_YTaAM', // https://youtu.be/nMb4L_YTaAM
    '4.5': 'pRNebahGlVU', // https://youtu.be/pRNebahGlVU
    '4.6': 's1NSYTn2-EE', // https://youtu.be/s1NSYTn2-EE
    '4.7': 'ZgDrWfqSlrU', // https://youtu.be/ZgDrWfqSlrU
    '4.8': 'eshMxTAmJ1Y', // https://youtu.be/eshMxTAmJ1Y
    '4.9': 'limVCAGF5BI', // https://youtu.be/limVCAGF5BI
    '4.10': '_egChWKSLoU', // https://youtu.be/_egChWKSLoU
    // Module 5
    '5.1': 'f8eqE1sGfno', // https://youtu.be/f8eqE1sGfno
    '5.2': '6WEhx-OPxgM', // https://youtu.be/6WEhx-OPxgM
    '5.3': 'mKt5bJfOiJQ', // https://youtu.be/mKt5bJfOiJQ
    '5.4': '0uGVF3vMuFY', // https://youtu.be/0uGVF3vMuFY
    '5.5': 'zLq9kg9mnd0', // https://youtu.be/zLq9kg9mnd0
    '5.6': 't9lpJ_al6BI', // https://youtu.be/t9lpJ_al6BI
    '5.7': 'WRTG75z3SkU', // https://youtu.be/WRTG75z3SkU
    '5.8': 'Gb1pgXY8exs', // https://youtu.be/Gb1pgXY8exs
    '5.9': '5xP_xSFKix0', // https://youtu.be/5xP_xSFKix0
    '5.10': 'oZLotZxzkEQ', // https://youtu.be/oZLotZxzkEQ
  };

  /// Resolved 11-char YouTube id, or null when this lesson has no clip yet.
  static String? youtubeIdFor(String lessonId) {
    final raw = youtubeIdByLesson[lessonId];
    if (raw == null || raw.trim().isEmpty) return null;
    return parseVideoId(raw);
  }

  /// True when [lessonId] should open the guide → video → guide gate.
  static bool hasVideo(String lessonId) => youtubeIdFor(lessonId) != null;

  /// Lesson ids that have a usable clip (id or URL), in catalog order.
  static List<String> lessonsWithVideo() => [
        for (final id in youtubeIdByLesson.keys)
          if (youtubeIdFor(id) != null) id,
      ];

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
