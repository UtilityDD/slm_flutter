// Perf regression guard for the dress-up (levels 2-10) and pole-inspect
// (levels 11-13) duty-slip games.
//
// For each scenario it pumps the real game widget on a 360x800 dp, DPR 2.0
// view (a 720p budget phone), lets images decode for real, then records:
//   * decoded image-cache bytes (imageCache.currentSizeBytes),
//   * widgets rebuilt per second while the player is idle,
//   * whether the idle screen still schedules frames,
// with and without the OS "remove animations" setting.
//
// Run with `flutter test test/perf/duty_games_perf_test.dart`; the numbers are
// printed so a before/after can be compared. The expectations below are the
// regression guards that the perf pass established.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/duty_slip/ds_dress_up.dart';
import 'package:slm_flutter/features/duty_slip/ds_pole_inspect.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_models.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

class _Sample {
  _Sample(this.label, this.imageMb, this.rebuildsPerSec, this.idleFrames);
  final String label;
  final double imageMb;
  final double rebuildsPerSec;
  final bool idleFrames;

  @override
  String toString() =>
      '$label: image cache ${imageMb.toStringAsFixed(1)} MB, idle rebuilds ${rebuildsPerSec.toStringAsFixed(0)}/s, idle schedules frames: $idleFrames';
}

var _rebuilds = 0;

void _muteAudio() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall _) async => 1;
  m.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), ok);
  m.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), ok);
}

Future<DutySlipEngine> _engineAt(int levelNumber) async {
  final pack = await DsPack.load();
  final e = DutySlipEngine(pack, seed: 7);
  e.openRoad();
  e.unlocked = dsLevels.length - 1;
  final index = dsLevels.indexWhere((l) => l.number == levelNumber);
  e.openLevel(index);
  e.openDress();
  assert(e.level.number == levelNumber && e.showingDress);
  return e;
}

Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<_Sample> _measure(WidgetTester tester, String label, int level, {required bool reduce}) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
  imageCache.clear();
  imageCache.clearLiveImages();

  final engine = (await tester.runAsync(() => _engineAt(level)))!;
  Future<void> speak(String _) async {}
  final game = level >= 11
      ? DsPoleInspect(engine: engine, onDone: () {}, muted: true, onSpeak: speak, onDelta: (_, _) {})
      : DsDressUp(engine: engine, onDone: () {}, muted: true, onSpeak: speak, onDelta: (_, _) {}, onBack: () {});
  await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(body: game))));
  await _decode(tester);

  // Let the intro play out: coach line, van arrival, coach leaving (L6).
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _decode(tester);
  final bytes = imageCache.currentSizeBytes;

  _rebuilds = 0;
  for (var i = 0; i < 125; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  final perSec = _rebuilds / 2.0;
  await tester.pump(const Duration(milliseconds: 16));
  final idle = tester.binding.hasScheduledFrame;

  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  tester.view.reset();
  return _Sample(label, bytes / (1024 * 1024), perSec, idle);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _muteAudio();
  // Keeps the shared clock player from being created (no audio plugin here).
  ZlFx.setMuted(true);
  setUp(() {
    debugOnRebuildDirtyWidget = (_, _) => _rebuilds++;
  });
  tearDown(() {
    debugOnRebuildDirtyWidget = null;
    // The mascot's lip-sync keeps a 12 s safety timer while it "speaks".
    MascotTalk.reset();
  });

  final results = <_Sample>[];

  // Baseline on c9ec1bd (anim / reduce): L2 13.1 MB 188/s ticking; L5 46.2 MB
  // 188/s ticking; L6 45.4 MB 0/s ticking; L7 46.4 MB 0/s ticking; L11 10.7 MB
  // 0/s idle. Every level kept ticking with animations removed.
  // After this pass: L2 7.4, L5 10.9, L6 11.8, L7 13.0, L11 8.4 MB; only the
  // L1-5 bob ticks (64 rebuilds/s, one AnimatedBuilder), nothing with reduce.
  const budgetMb = {2: 10.0, 5: 16.0, 6: 18.0, 7: 18.0, 11: 11.0};
  const names = {2: 'helmet tray', 5: 'full kit', 6: 'van shelf', 7: 'pole van', 11: 'pole inspect'};
  for (final reduce in [false, true]) {
    final tag = reduce ? 'reduce' : 'anim';
    for (final level in budgetMb.keys) {
      testWidgets('L$level ${names[level]} ($tag)', (tester) async {
        final s = await _measure(tester, 'L$level $tag', level, reduce: reduce);
        results.add(s);
        // ignore: avoid_print
        print(s);
        expect(s.imageMb, lessThan(budgetMb[level]!), reason: 'tray and coach art must decode at display size');
        final bob = !reduce && level <= 5;
        if (bob) {
          // Only the idle bob ticks; the coach and shelf must not rebuild per frame.
          expect(s.rebuildsPerSec, lessThan(80));
        } else {
          expect(s.idleFrames, isFalse, reason: 'idle screen must not keep scheduling frames');
          expect(s.rebuildsPerSec, lessThan(5));
        }
      });
    }
  }

  tearDownAll(() {
    // ignore: avoid_print
    print('--- duty-games perf ---\n${results.join('\n')}');
  });
}
