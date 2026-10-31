import 'package:flutter/widgets.dart';

/// Shared switches for every motion widget below a [SlmMotionScope].
///
/// Without a scope, widgets behave as if playing with loops on. The device
/// "remove animations" setting always wins over these switches.
class SlmMotionSettings extends ChangeNotifier {
  bool _paused = false;
  bool _loops = true;
  int _replay = 0;

  /// Freezes looping motion where it is.
  bool get paused => _paused;

  /// Continuous decoration (float, ring spin, shine, pulse) on or off.
  bool get loops => _loops;

  /// Bumped by [replayEntrances]; entrance widgets replay when it changes.
  int get replay => _replay;

  void pause() => _set(paused: true);
  void play() => _set(paused: false);
  void setLoops(bool value) => _set(loops: value);

  void replayEntrances() {
    _replay++;
    notifyListeners();
  }

  void _set({bool? paused, bool? loops}) {
    final p = paused ?? _paused;
    final l = loops ?? _loops;
    if (p == _paused && l == _loops) return;
    _paused = p;
    _loops = l;
    notifyListeners();
  }
}

class SlmMotionScope extends InheritedNotifier<SlmMotionSettings> {
  const SlmMotionScope({super.key, required SlmMotionSettings settings, required super.child})
      : super(notifier: settings);

  static SlmMotionSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SlmMotionScope>()?.notifier;
}

/// True when the user asked the OS to remove animations.
bool slmReduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Whether looping decoration may run here. Registers a dependency, so call
/// it from build or didChangeDependencies to be told about changes.
bool slmLoopsOn(BuildContext context) {
  if (slmReduceMotion(context)) return false;
  final s = SlmMotionScope.maybeOf(context);
  return s == null || (!s.paused && s.loops);
}

/// Current replay token (0 without a scope).
int slmReplayToken(BuildContext context) => SlmMotionScope.maybeOf(context)?.replay ?? 0;
