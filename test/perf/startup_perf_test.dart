// Cold-start guards: what runs before the first frame, what the first frame
// builds and loads. Each test prints a `PERF startup` line so before/after
// runs can be compared; the expectations are the fixed numbers.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/core/network/supabase_service.dart';
import 'package:slm_flutter/core/startup/app_memory.dart';
import 'package:slm_flutter/core/startup/startup_trace.dart';
import 'package:slm_flutter/core/theme/app_theme.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/main.dart';

/// Every SharedPreferences platform load (`getAll*`): the real cost of
/// `SharedPreferences.getInstance()`, which caches after its first call.
int _prefsLoads = 0;

/// Every asset key read through the `flutter/assets` channel.
final _assets = <String>[];

String _b64(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

/// What the phone has saved: a signed-in lineman (token valid until 2100) and
/// the last profile row fetched for them. The test binding answers every HTTP
/// request with 400, i.e. the phone is offline.
final Map<String, Object> _savedPrefs = {
  'flutter.sb-wkunyvomogeazjwtenck-auth-token': jsonEncode({
    'access_token': '${_b64({'alg': 'HS256', 'typ': 'JWT'})}.${_b64({'sub': 'u1', 'exp': 4102444800})}.sig',
    'token_type': 'bearer',
    'refresh_token': 'r1',
    'user': {
      'id': 'u1',
      'aud': 'authenticated',
      'email': 'rahim@example.com',
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': <String, Object>{},
      'user_metadata': {'full_name': 'Google Rahim'},
    },
  }),
  'flutter.auth_profile_cache_v1': jsonEncode({
    'uid': 'u1',
    'row': {'id': 'u1', 'full_name': 'রহিম মিয়া', 'points': 120, 'verified': true},
  }),
};

void _mockPlatform() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/shared_preferences'), (call) async {
    if (call.method.startsWith('getAll')) {
      _prefsLoads++;
      return _savedPrefs;
    }
    return true;
  });
  // Same lookup as flutter_test's own asset mock, plus a log of the keys.
  final root = Platform.environment['UNIT_TEST_ASSETS'];
  messenger.setMockMessageHandler('flutter/assets', (message) {
    final key = utf8.decode(message!.buffer.asUint8List());
    _assets.add(key);
    if (root == null) return null;
    final file = File('$root/$key');
    if (!file.existsSync()) return null;
    return SynchronousFuture(Uint8List.fromList(file.readAsBytesSync()).buffer.asByteData());
  });
}

String _ms(List<({String name, int ms})> steps) =>
    steps.isEmpty ? 'none' : steps.map((s) => '${s.name} ${s.ms} ms').join(', ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _mockPlatform();

  // A plain test (real async), so Supabase's refresh timer is not a FakeAsync leak.
  test('nothing slow is awaited before runApp', () async {
    StartupTrace.reset();
    _prefsLoads = 0;
    final sw = Stopwatch()..start();
    bootstrap(); // returns void: runApp follows at once
    final beforeRunApp = sw.elapsedMilliseconds;
    final prefsBefore = _prefsLoads;
    final blocking = StartupTrace.blocking;
    debugPrint('PERF startup before runApp: $beforeRunApp ms, awaited steps ${blocking.length} '
        '(${_ms(blocking)}), prefs loads $prefsBefore, Supabase started ${SupabaseService.hasClient}');
    expect(blocking, isEmpty, reason: 'nothing may be awaited before the first frame');
    expect(prefsBefore, 0, reason: 'SharedPreferences loads after the first frame');
    expect(SupabaseService.hasClient, isFalse, reason: 'Supabase starts after the first frame');
    expect(beforeRunApp, lessThan(20));
  });

  // Runs while Supabase is still waiting for the first frame (no frame is
  // pumped here, so the 1 s fallback starts it): the deferred path.
  test('signed-in lineman is restored offline after a deferred start', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = container.read(authProvider);
    expect(first.isLoading, isTrue, reason: 'first frame shows loading, as before');
    expect(first.profile, isNull);

    final sw = Stopwatch()..start();
    expect(await SupabaseService.ready, isTrue);
    final readyMs = sw.elapsedMilliseconds;
    var auth = container.read(authProvider);
    for (var i = 0; i < 100 && (auth.isLoading || auth.profile == null); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      auth = container.read(authProvider);
    }
    debugPrint('PERF startup supabase ready after $readyMs ms (incl. first-frame wait); '
        'background: ${_ms(StartupTrace.background)}; prefs loads $_prefsLoads; '
        'auth: signedIn ${auth.isAuthenticated} offline ${auth.offline} name ${auth.profile?.fullName}');
    expect(auth.isAuthenticated, isTrue, reason: 'offline must not sign the lineman out');
    expect(auth.offline, isTrue);
    expect(auth.profile!.id, 'u1');
    expect(auth.profile!.fullName, 'রহিম মিয়া', reason: 'last saved profile, not invented data');
    // The plugin caches the instance: every getInstance() shares one load.
    expect(_prefsLoads, 1);
  });

  test('MaterialApp theme is built once, light only', () {
    expect(identical(AppTheme.lightTheme, AppTheme.lightTheme), isTrue);
    expect(AppTheme.lightTheme.brightness, Brightness.light);
  });

  group('image cache budget (3-4 GB phones)', () {
    test('every tier still fits the heaviest screen', () {
      const gb = 1024 * 1024; // kB
      final tiers = {
        'unknown': imageCacheBudgetFor(null),
        '2 GB': imageCacheBudgetFor((1.8 * gb).round()),
        '3 GB': imageCacheBudgetFor((2.8 * gb).round()),
        '4 GB': imageCacheBudgetFor((3.7 * gb).round()),
        '6 GB': imageCacheBudgetFor((5.6 * gb).round()),
        '8 GB': imageCacheBudgetFor((7.5 * gb).round()),
      };
      debugPrint('PERF startup image cache budgets: ${tiers.map((k, v) => MapEntry(k, '${v.bytes >> 20} MB/${v.entries}'))}');
      for (final b in tiers.values) {
        // 18 MB = budget of the heaviest screen in duty_games_perf_test.dart.
        expect(b.bytes, greaterThanOrEqualTo(imageCacheFloorBytes));
        expect(imageCacheFloorBytes, greaterThan(18 * 1024 * 1024));
        expect(b.bytes, lessThanOrEqualTo(flutterDefaultImageCache.bytes));
      }
      expect(tiers['4 GB']!.bytes, 48 << 20);
      expect(tiers['8 GB'], flutterDefaultImageCache);
      expect(parseMemTotalKb('MemTotal:        3809268 kB\nMemFree:  1 kB'), 3809268);
      expect(parseMemTotalKb('garbage'), isNull);
    });

    testWidgets('memory pressure empties the cache and halves the budget', (tester) async {
      AppMemory.install(); // no-op if bootstrap already did it
      applyImageCacheBudget(imageCacheBudgetFor((3.7 * 1024 * 1024).round()));
      tester.binding.handleMemoryPressure();
      final cache = PaintingBinding.instance.imageCache;
      debugPrint('PERF startup after memory pressure: ${cache.maximumSizeBytes >> 20} MB/${cache.maximumSize}');
      expect(cache.currentSizeBytes, 0);
      expect(cache.maximumSizeBytes, 24 << 20);
      expect(cache.maximumSize, 150);
      tester.binding.handleMemoryPressure();
      expect(cache.maximumSizeBytes, imageCacheFloorBytes, reason: 'never below the heaviest screen');
      applyImageCacheBudget(flutterDefaultImageCache);
    });
  });

  testWidgets('first frame builds Home only and loads only its art', (tester) async {
    _assets.clear();
    _prefsLoads = 0;
    final sw = Stopwatch()..start();
    await tester.pumpWidget(const ProviderScope(child: SmartLinemanApp()));
    final firstFrameMs = sw.elapsedMilliseconds;
    final elements = tester.allElements.length;
    final firstFrameAssets = [..._assets];
    final firstFramePrefs = _prefsLoads;

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final firstSecond = _assets.toSet();
    debugPrint('PERF startup first frame: $firstFrameMs ms, $elements elements, '
        'assets ${firstFrameAssets.length} ${firstFrameAssets.toSet()}, prefs loads $firstFramePrefs; '
        'first second: ${firstSecond.length} assets $firstSecond, prefs loads $_prefsLoads');

    // Home shows the shield (3 layers) after AssetManifest; no sounds or
    // other screens' art may load at startup. One JSON is allowed since the
    // Nov 2026 home redesign: Home's card names the next rung (`L<n>`, its
    // module's progress), which needs the ladder catalog. Home reads it after
    // its first frame (never in it, checked below) — the same file the
    // warm-up preloads under the splash in the app.
    const catalog = 'assets/game/catalog/content_catalog.json';
    expect(firstFrameAssets, isNot(contains(catalog)), reason: 'the first frame stays light');
    final unexpected = firstSecond.where((k) =>
        k != 'AssetManifest.bin' &&
        k != catalog &&
        !k.startsWith('assets/brand/') &&
        !k.startsWith('assets/fonts/'));
    expect(unexpected, isEmpty, reason: 'only Home art may load in the first second');
    expect(_prefsLoads, lessThanOrEqualTo(1), reason: 'SharedPreferences is loaded once and shared');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
