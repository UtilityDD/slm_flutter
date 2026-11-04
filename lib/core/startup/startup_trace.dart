import 'dart:async';

/// Timings of the work done while the app starts. Only a few [Stopwatch]
/// reads, so it stays on in release; `test/perf/startup_perf_test.dart`
/// reads it to guard that nothing slow is awaited before the first frame.
abstract final class StartupTrace {
  static final List<({String name, int ms})> _blocking = [];
  static final List<({String name, int ms})> _background = [];

  /// Steps awaited before `runApp` (they delay the first frame).
  static List<({String name, int ms})> get blocking => List.unmodifiable(_blocking);

  /// Steps started before `runApp` that finish after it.
  static List<({String name, int ms})> get background => List.unmodifiable(_background);

  /// Awaits [work] before the first frame. Keep this list empty if you can.
  static Future<T> blockingStep<T>(String name, Future<T> Function() work) async {
    final sw = Stopwatch()..start();
    try {
      return await work();
    } finally {
      _blocking.add((name: name, ms: sw.elapsedMilliseconds));
    }
  }

  /// Starts [work] without waiting for it and records how long it took.
  static Future<T> backgroundStep<T>(String name, Future<T> Function() work) {
    final sw = Stopwatch()..start();
    return work().whenComplete(() => _background.add((name: name, ms: sw.elapsedMilliseconds)));
  }

  static void reset() {
    _blocking.clear();
    _background.clear();
  }
}
