// Performance guards for the duty-slip page (DutySlipPage).
//
// Pumps the real page with mocked plugins (SharedPreferences, audioplayers,
// flutter_tts) and measures:
//   * idle tickers once a screen settles under "remove animations",
//   * HUD rebuilds per second from the level clock,
//   * full game-tree rebuilds caused by one scored tap (+5 fly-up),
//   * whether the level clock keeps counting while the app is in background,
//   * rebuilds per second on settled brief / result boards,
//   * decoded bytes for a 58 dp thumbnail (DsBoxDecode vs a full decode).
//
// Set PERF_PRINT=1 to print the numbers.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/admin/dev_unlock.dart';
import 'package:slm_flutter/features/duty_slip/adventure_map.dart';
import 'package:slm_flutter/features/duty_slip/ds_dress_up.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_engine.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_page.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';

final _counts = <String, int>{};

void _startCount() {
  _counts.clear();
  debugOnRebuildDirtyWidget = (Element e, bool builtOnce) {
    final n = e.widget.runtimeType.toString();
    _counts[n] = (_counts[n] ?? 0) + 1;
  };
}

Map<String, int> _stopCount() {
  debugOnRebuildDirtyWidget = null;
  return Map.of(_counts);
}

int _total(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

void _log(String s) {
  if (Platform.environment['PERF_PRINT'] == '1') {
    // ignore: avoid_print
    print('[duty-page perf] $s');
  }
}

Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  const step = Duration(milliseconds: 16);
  var left = d;
  while (left > Duration.zero) {
    await tester.pump(step);
    left -= step;
  }
}

/// expect(), unless PERF_BASELINE=1 (record numbers on unfixed code).
void _check(Object? actual, Matcher matcher, {String? reason}) {
  if (Platform.environment['PERF_BASELINE'] == '1') return;
  expect(actual, matcher, reason: reason);
}

void _mockPlugins() {
  SharedPreferences.setMockInitialValues({});
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> ok(MethodCall c) async => c.method.contains('get') ? null : 1;
  for (final name in [
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
    'flutter_tts',
    'plugins.flutter.io/firebase_core',
  ]) {
    m.setMockMethodCallHandler(MethodChannel(name), ok);
  }
}

class _DevOpen extends DevUnlockNotifier {
  @override
  bool build() => true;
}

void Function(FlutterErrorDetails)? _prevOnError;

/// Audio event channels use random ids, so they cannot be mocked by name;
/// drop their MissingPluginException noise and keep every other error.
void _quietPlugins() {
  _prevOnError = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exception is MissingPluginException) return;
    _prevOnError?.call(d);
  };
}

Widget _app({required bool reduceMotion, bool startOnRoad = true}) {
  return ProviderScope(
    overrides: [devUnlockProvider.overrideWith(_DevOpen.new)],
    child: MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: DutySlipPage(startOnRoad: startOnRoad),
    ),
  );
}

Future<void> _boot(WidgetTester tester, {required bool reduceMotion}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  _quietPlugins();
  await tester.pumpWidget(_app(reduceMotion: reduceMotion));
  for (var i = 0; i < 40 && find.byType(AdventureMap).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(AdventureMap), findsOneWidget, reason: 'page should boot to the ladder');
}

Future<DutySlipEngine> _openLevel(WidgetTester tester, int index) async {
  final map = tester.widget<AdventureMap>(find.byType(AdventureMap));
  map.engine.unlocked = 40;
  map.onOpen(index);
  await _pumpFor(tester, const Duration(milliseconds: 600));
  return map.engine;
}

Future<void> _teardown(WidgetTester tester) async {
  // The mascot's lip-sync keeps a 12 s safety timer while it "speaks".
  MascotTalk.reset();
  await tester.pumpWidget(const SizedBox());
  await _pumpFor(tester, const Duration(seconds: 2));
  FlutterError.onError = _prevOnError;
}

void main() {
  setUp(_mockPlugins);

  testWidgets('settled ladder schedules no page-level ticker under reduce motion', (tester) async {
    await _boot(tester, reduceMotion: true);
    await _pumpFor(tester, const Duration(seconds: 3));
    final tickers = tester.binding.transientCallbackCount;
    // Pump a few more frames and see if any frame is still requested.
    await _pumpFor(tester, const Duration(milliseconds: 500));
    final scheduled = tester.binding.hasScheduledFrame;
    _log('ladder idle (reduce motion): transientCallbacks=$tickers hasScheduledFrame=$scheduled');
    // Before: 2 (page _skyDrift + the ladder map). Any one left is the map's.
    _check(tickers, lessThanOrEqualTo(1), reason: 'page must not run an idle ticker');
    await _teardown(tester);
  });

  testWidgets('dress intro: HUD rebuilds per second while idle', (tester) async {
    await _boot(tester, reduceMotion: true);
    final e = await _openLevel(tester, 0);
    expect(e.showingDressIntro, isTrue);
    await _pumpFor(tester, const Duration(seconds: 1));
    _startCount();
    await _pumpFor(tester, const Duration(seconds: 2));
    final c = _stopCount();
    final hud = (c['_Hud'] ?? 0) / 2;
    final clock = (c['_HudClock'] ?? 0) / 2;
    _log('dress intro idle: _Hud rebuilds/s=$hud clock rebuilds/s=$clock total rebuilds/s=${_total(c) / 2} top=${_top(c)}');
    _check(hud, lessThanOrEqualTo(1), reason: 'HUD must not rebuild at 10 Hz on an idle intro');
    await _teardown(tester);
  });

  testWidgets('dress level: one scored tap does not rebuild the game tree', (tester) async {
    await _boot(tester, reduceMotion: true);
    final e = await _openLevel(tester, 1); // level 2, helmet tray
    // Tap the intro's forward arrow to open the dress-up board.
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded).last);
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.byType(DsDressUp), findsOneWidget);
    expect(e.showingDress, isTrue);
    final dress = tester.widget<DsDressUp>(find.byType(DsDressUp));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    _startCount();
    dress.onDelta(5, const Offset(200, 600));
    await _pumpFor(tester, const Duration(milliseconds: 1000));
    final c = _stopCount();
    final dressBuilds = c['DsDressUp'] ?? 0;
    _log('scored tap: DsDressUp rebuilds=$dressBuilds total rebuilds=${_total(c)} '
        'fly rebuilds=${c['_FlyingScore'] ?? 0}');
    _check(dressBuilds, equals(0), reason: 'a +5 fly-up must not rebuild the dress-up board');

    // Level clock vs background.
    e.beginDress();
    await _pumpFor(tester, const Duration(seconds: 3));
    final before = e.playSeconds;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    final paused = e.playSeconds;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpFor(tester, const Duration(seconds: 2));
    final after = e.playSeconds;
    _log('clock: before pause=$before, after 20 s in background=$paused, 2 s after resume=$after');
    _check(paused - before, lessThanOrEqualTo(1), reason: 'clock must stop in background');
    _check(after - paused, inInclusiveRange(1, 3), reason: 'clock must resume');

    // HUD during live play: ticks once a second.
    _startCount();
    await _pumpFor(tester, const Duration(seconds: 3));
    final live = _stopCount();
    _log('live dress play: _Hud rebuilds/s=${(live['_Hud'] ?? 0) / 3} '
        'clock rebuilds/s=${(live['_HudClock'] ?? 0) / 3}');
    _check((live['_Hud'] ?? 0) / 3, lessThanOrEqualTo(1.5));

    // Finish -> back on the ladder (e05c011 skips the old medal result board).
    // Idle cost of the ladder itself is covered by ladder_perf_test.dart; here
    // the catalog never finishes loading, so its boot spinner would spin.
    dress.onDone();
    await _pumpFor(tester, const Duration(seconds: 4));
    expect(e.showingResult, isFalse);
    expect(e.onRoad, isTrue);
    await _teardown(tester);
  });

  testWidgets('job brief board, settled: rebuilds per second', (tester) async {
    await _boot(tester, reduceMotion: false);
    final e = await _openLevel(tester, 22); // level 23, a job
    expect(e.listing && e.level.isJob, isTrue);
    await _pumpFor(tester, const Duration(seconds: 4));
    _startCount();
    await _pumpFor(tester, const Duration(seconds: 2));
    final c = _stopCount();
    final pulse = (c['ScaleTransition'] ?? 0) / 2;
    final total = _total(c) / 2 - pulse;
    _log('job brief settled (animations on): rebuilds/s=${_total(c) / 2} '
        '(ScaleTransition leaves=$pulse, rest=$total) top=${_top(c)}');
    // The 3% pulse on the group buttons is a ScaleTransition leaf per button;
    // nothing else on the board may rebuild per frame.
    _check(total, lessThanOrEqualTo(10));
    _check(pulse, lessThanOrEqualTo(6 * 64));
    await _teardown(tester);
  });

  testWidgets('job brief board honours reduce motion', (tester) async {
    await _boot(tester, reduceMotion: true);
    final ladder = tester.binding.transientCallbackCount;
    await _openLevel(tester, 22);
    await _pumpFor(tester, const Duration(seconds: 4));
    _startCount();
    await _pumpFor(tester, const Duration(seconds: 1));
    final c = _stopCount();
    _log('job brief settled (reduce motion): rebuilds/s=${_total(c)} '
        'transientCallbacks=${tester.binding.transientCallbackCount} (ladder had $ladder)');
    _check(_total(c), lessThanOrEqualTo(5));
    await _teardown(tester);
  });

  testWidgets('58 dp thumbnail decodes near display size', (tester) async {
    const path = 'assets/safety/library/ppe/Electrical_Gloves.webp'; // 960x960
    final full = await tester.runAsync(() => _decodedBytes(const AssetImage(path)));
    final boxed = await tester.runAsync(
      () => _decodedBytes(const DsBoxDecode(AssetImage(path), width: 174, height: 174, cover: true)),
    );
    _log('58 dp @3x thumbnail: full decode=$full B, box decode=$boxed B');
    _check(boxed!, lessThan(full! ~/ 10));
  });
}

String _top(Map<String, int> m) {
  final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return l.take(5).map((e) => '${e.key}:${e.value}').join(', ');
}

Future<int> _decodedBytes(ImageProvider p) async {
  final stream = p.resolve(ImageConfiguration.empty);
  final done = Completer<ui.Image>();
  late ImageStreamListener l;
  l = ImageStreamListener((info, _) {
    done.complete(info.image.clone());
    stream.removeListener(l);
  }, onError: (e, s) => done.completeError(e, s));
  stream.addListener(l);
  final img = await done.future;
  final bytes = img.width * img.height * 4;
  img.dispose();
  return bytes;
}
