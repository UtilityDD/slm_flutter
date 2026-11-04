// Runtime guards for the screens outside the game: emergency directory,
// route transitions, the leaderboard and the bundled JSON packs. Each test
// prints a `PERF` line so before/after runs can be compared.
//
// Baseline on d685bb7 -> after (macOS host; parse/ms numbers are noisy on a
// shared machine, the counts are exact):
//   emergency JSON ....................... 335,159 B, 9 fields/row -> 117,201 B, 5 fields
//   hourly pack JSON ..................... 842,815 B -> 757,271 B (empty image/tags/visual dropped)
//   emergency "Power", all districts ..... 494 cards built eagerly -> 0 (ListView.builder, 4 mounted)
//   SlmPageRoute push + 6 rebuilds + pop . 34 CurvedAnimations created, 0 disposed -> 1 created, 1 disposed
//   Rank opened 3 times in a session ..... 3 network fetches -> 1
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/emergency/emergency_directory_screen.dart';
import 'package:slm_flutter/features/quizzes/hourly_pack.dart';
import 'package:slm_flutter/features/quizzes/leaderboard_provider.dart';

class _TestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(profile: LinemanProfile(id: 'u1'));
}

class _CountingBoard extends LeaderboardSource {
  int fetches = 0;

  @override
  Future<List<LeaderboardEntry>> fetch() async {
    fetches++;
    return const [LeaderboardEntry(rank: 1, id: 'a', name: 'Real One', district: 'Howrah', points: 90, level: 2)];
  }
}

/// Counts CurvedAnimation objects created and disposed while [body] runs.
Future<(int created, int disposed)> _curves(Future<void> Function() body) async {
  var created = 0;
  var disposed = 0;
  void listen(ObjectEvent e) {
    if (e.object is! CurvedAnimation) return;
    if (e is ObjectCreated) created++;
    if (e is ObjectDisposed) disposed++;
  }

  FlutterMemoryAllocations.instance.addListener(listen);
  try {
    await body();
  } finally {
    FlutterMemoryAllocations.instance.removeListener(listen);
  }
  return (created, disposed);
}

void main() {
  group('bundled JSON packs', () {
    test('emergency directory: minified, only the fields the screen reads', () {
      final file = File('assets/data/districtEmergencyServices.json');
      final raw = file.readAsStringSync();
      parseEmergencyDirectory(raw); // warm up
      final sw = Stopwatch()..start();
      for (var i = 0; i < 5; i++) {
        parseEmergencyDirectory(raw);
      }
      final parseMs = (sw.elapsedMicroseconds / 5000).toStringAsFixed(1);
      final dir = parseEmergencyDirectory(raw);
      final rows = jsonDecode(raw) as List;
      final fields = {for (final r in rows) ...(r as Map).keys};
      debugPrint('PERF emergency JSON ${file.lengthSync()} B, fields $fields, parse $parseMs ms, '
          '${dir.items.length} rows');
      expect(dir.items.length, greaterThan(900));
      expect(fields, {'name', 'type', 'district', 'location', 'phone'});
      expect(file.lengthSync(), lessThan(130000));
      expect(raw.contains('\n  '), isFalse, reason: 'keep the asset minified');
    });

    test('hourly pack: minified, empty fields dropped, same questions', () {
      final file = File('assets/data/hourly_quiz_pack.json');
      final raw = file.readAsStringSync();
      parseHourlyPack(raw); // warm up
      final sw = Stopwatch()..start();
      for (var i = 0; i < 5; i++) {
        parseHourlyPack(raw);
      }
      final parseMs = (sw.elapsedMicroseconds / 5000).toStringAsFixed(1);
      final pack = parseHourlyPack(raw);
      debugPrint('PERF hourly pack JSON ${file.lengthSync()} B, parse $parseMs ms, '
          '${pack.questions.length} questions, ${pack.questions.where((q) => q.visual).length} visual');
      expect(pack.questions.length, greaterThan(900));
      expect(pack.questions.where((q) => q.visual).length, greaterThan(100));
      expect(pack.questions.where((q) => q.image.isNotEmpty).length, greaterThan(100));
      expect(file.lengthSync(), lessThan(780000));
      expect(raw.contains('"image":""'), isFalse);
      expect(raw.contains(', "'), isFalse, reason: 'keep the asset minified');
    });
  });

  group('emergency directory screen', () {
    testWidgets('a big group builds only the cards on screen', (tester) async {
      await tester.runAsync(loadEmergencyDirectory);
      await tester.pumpWidget(ProviderScope(
        overrides: [authProvider.overrideWith(_TestAuth.new)],
        child: MaterialApp(theme: SlmTheme.night(), home: const EmergencyDirectoryScreen()),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      await tester.pump();

      final sw = Stopwatch()..start();
      await tester.tap(find.text('বিদ্যুৎ'));
      await tester.pump();
      final openMs = sw.elapsedMilliseconds;
      final cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_ContactCard');
      final built = tester.widgetList(cards).length;
      // Widgets made up front by list-style scroll views (all of them, on or off screen).
      final eager = tester
          .widgetList<ListView>(find.byType(ListView))
          .map((l) => l.childrenDelegate)
          .whereType<SliverChildListDelegate>()
          .fold<int>(0, (n, d) => n + d.children.length);

      // Typing in "All districts": each keystroke re-filters and rebuilds the list.
      const typed = ['k', 'ko', 'kol', 'ko', 'k', ''];
      sw.reset();
      for (final q in typed) {
        await tester.enterText(find.byType(TextField), q);
        await tester.pump();
      }
      final keyMs = sw.elapsedMicroseconds / typed.length / 1000;
      // Rebuild without any change (chip-free setState path, e.g. keyboard inset).
      sw.reset();
      for (var i = 0; i < 10; i++) {
        tester.binding.handleMetricsChanged();
        await tester.pump();
      }
      final idleMs = sw.elapsedMicroseconds / 10 / 1000;
      debugPrint('PERF emergency power/all districts: $built cards mounted, $eager widgets built eagerly, open $openMs ms, '
          'keystroke ${keyMs.toStringAsFixed(1)} ms, metrics rebuild ${idleMs.toStringAsFixed(1)} ms');
      expect(built, greaterThan(0));
      expect(eager, lessThan(40));
    });
  });

  group('route transitions', () {
    testWidgets('SlmPageRoute builds its curves once and disposes them', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final tick = ValueNotifier(0);
      await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const SizedBox()));
      final (created, disposed) = await _curves(() async {
        key.currentState!.push(SlmPageRoute<void>(
          builder: (_) => ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (_, v, _) => Text('$v', textDirection: TextDirection.ltr),
          ),
        ));
        await tester.pumpAndSettle();
        // Changing the route's internal state rebuilds its transitions.
        final route = ModalRoute.of(tester.element(find.text('0')))!;
        for (var i = 0; i < 6; i++) {
          route.changedInternalState();
          await tester.pump();
        }
        key.currentState!.pop();
        await tester.pumpAndSettle();
      });
      debugPrint('PERF SlmPageRoute push + 6 rebuilds + pop: $created CurvedAnimations created, $disposed disposed');
      expect(created, lessThanOrEqualTo(4));
      expect(disposed, created);
      tick.dispose();
    });
  });

  group('leaderboard', () {
    test('Rank opened three times in one session fetches once', () async {
      SharedPreferences.setMockInitialValues({});
      final source = _CountingBoard();
      final container = ProviderContainer(overrides: [leaderboardSourceProvider.overrideWithValue(source)]);
      addTearDown(container.dispose);
      for (var i = 0; i < 3; i++) {
        final sub = container.listen(liveLeaderboardProvider, (_, _) {});
        await container.read(liveLeaderboardProvider.future);
        sub.close();
        await Future<void>.delayed(Duration.zero);
      }
      debugPrint('PERF Rank x3 in a session: ${source.fetches} network fetches');
      expect(source.fetches, 1);

      // A finished hourly quiz (or pull-to-refresh) asks for a fresh board.
      container.invalidate(liveLeaderboardProvider);
      final sub = container.listen(liveLeaderboardProvider, (_, _) {});
      await container.read(liveLeaderboardProvider.future);
      sub.close();
      expect(source.fetches, 2);
    });
  });
}
