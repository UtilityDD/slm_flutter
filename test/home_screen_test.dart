// Home → one tap → ladder (Nov 2026 redesign): the "continue" card names the
// next rung the ladder will open on (L<n>, its module's progress and stars),
// the gold button opens the ladder, chips appear only when true, the verify
// chip has three states, the all-done state, no overflow on four phone
// sizes with 48 dp touch targets, and an idle Home draws no frames.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/design/slm_design.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/duty_slip/duty_slip_page.dart';
import 'package:slm_flutter/features/duty_slip/ladder_focus.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/ladder_builder.dart';
import 'package:slm_flutter/features/home/home_screen.dart';
import 'package:slm_flutter/features/home/home_toolbox.dart';
import 'package:slm_flutter/features/rank/league_board.dart';

late BuiltLadder _built;

enum _Who { guest, pending, verified }

class _Auth extends AuthNotifier {
  _Auth(this.who);
  final _Who who;

  @override
  AuthState build() => AuthState(
        profile: switch (who) {
          _Who.guest => LinemanProfile.guest(),
          _Who.pending => const LinemanProfile(id: 'u1', fullName: 'রহিম মিয়া', verified: false, district: 'Hooghly'),
          _Who.verified => const LinemanProfile(id: 'u1', fullName: 'রহিম মিয়া', verified: true, district: 'Hooghly'),
        },
      );
}

class _League extends LeagueBoardSource {
  const _League(this.myRank);
  final int? myRank;

  @override
  Future<List<LeagueRow>> month({required int year, required int month, String? district}) async {
    final rank = myRank;
    if (rank == null) throw StateError('offline');
    return [
      const LeagueRow(rank: 1, name: 'অন্য', district: 'Hooghly', points: 900, rungs: 20),
      LeagueRow(rank: rank, name: 'রহিম মিয়া', district: 'Hooghly', points: 300, rungs: 3, isMe: true),
    ];
  }

  @override
  Future<List<LeagueRow>> allTime({String? district}) async => const [];
  @override
  Future<List<LeagueWin>> myWins() async => const [];
  @override
  Future<bool> myShowName() async => true;
  @override
  Future<bool> setShowName(bool value) async => true;
}

/// Three Module 1 rungs cleared, stars on the Do ones; [chest]: a gift
/// dropped by the third rung's first clear.
GameSave _seeded({bool chest = false}) {
  final ids = [for (var i = 0; i < 3; i++) _built.rungs[i].id];
  return GameSave.empty.copyWith(
    points: 240,
    deaths: 1,
    rungProgress: {for (final id in ids) id: 'cleared'},
    starsByRung: {for (var i = 0; i < 3; i++) if (!_built.rungs[i].isLearn) ids[i]: 2},
    toolbox: chest ? ToolboxSave(chests: [PendingChest(rungId: ids[2])]) : const ToolboxSave(),
  );
}

GameSave _allCleared() {
  final span = ladderPlayableSpan(_built);
  return GameSave.empty.copyWith(rungProgress: {for (var i = 0; i < span; i++) _built.rungs[i].id: 'cleared'});
}

final _opened = <int?>[];

Future<void> _pump(
  WidgetTester t, {
  GameSave? save,
  _Who who = _Who.verified,
  int? leagueRank,
  Size size = const Size(360, 740),
}) async {
  SharedPreferences.setMockInitialValues({
    if (save != null) 'game_save_v1': jsonEncode(save.toJson()),
  });
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  _opened.clear();
  await t.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _Auth(who)),
      builtLadderProvider.overrideWith((ref) async => _built),
      leagueBoardSourceProvider.overrideWithValue(_League(leagueRank)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          ladderBuilder: (anchor) {
            _opened.add(anchor);
            return Scaffold(body: Text('ladder:$anchor'));
          },
        ),
      ),
    ),
  ));
  for (var i = 0; i < 30; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _built = const LadderBuilder().build(await ContentCatalog.loadAsset());
  });

  testWidgets('the card shows the next rung, its module, progress and stars', (t) async {
    await _pump(t, save: _seeded());
    final next = ladderNext(_built, _seeded(), ladderFocus(_built, _seeded(), 0));
    expect(next.index, 3, reason: 'three rungs cleared: the fourth is next');
    expect(find.text('L4'), findsOneWidget);
    expect(find.text('মডিউল 1'), findsOneWidget);
    expect(find.text('3/${next.total} ধাপ'), findsOneWidget);
    expect(next.total, 30);
    if (next.starsMax > 0) expect(find.text('${next.stars}/${next.starsMax}'), findsOneWidget);
    expect(find.text('চলুন, L4'), findsOneWidget);
    expect(find.text('ঘরে আপনার জন্য কেউ অপেক্ষা করছে।'), findsOneWidget);
    // English digits only.
    expect(find.textContaining(RegExp('[০-৯]')), findsNothing);
    await _done(t);
  });

  testWidgets('the gold button opens the ladder at the current rung', (t) async {
    await _pump(t, save: _seeded());
    await t.tap(find.text('চলুন, L4'));
    await t.pumpAndSettle();
    expect(_opened, [null], reason: 'no anchor: the ladder opens on its own current rung');
    expect(find.text('ladder:null'), findsOneWidget);
    // The app's ladder is the real duty-slip page, opened at an anchor.
    expect(HomeScreen.ladder(null), isA<DutySlipPage>().having((p) => p.anchor, 'anchor', isNull));
    expect(HomeScreen.ladder(3), isA<DutySlipPage>().having((p) => p.anchor, 'anchor', 3));
    await _done(t);
  });

  testWidgets('chips appear only when true', (t) async {
    await _pump(t, save: _seeded(), leagueRank: null);
    expect(find.byKey(const ValueKey('home-chip-gift')), findsNothing);
    expect(find.byKey(const ValueKey('home-chip-league')), findsNothing, reason: 'offline, nothing saved: hidden');
    await _done(t);

    await _pump(t, save: _seeded(chest: true), leagueRank: 4);
    expect(find.text('🎁 1টি উপহার অপেক্ষা করছে'), findsOneWidget);
    expect(find.text('🏆 জেলায় #4'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('home-chip-gift')));
    await t.pumpAndSettle();
    expect(_opened, [3], reason: 'the chest stands one rung above the rung that dropped it');
    await _done(t);
  });

  testWidgets('the league chip is for verified members only', (t) async {
    await _pump(t, save: _seeded(), who: _Who.pending, leagueRank: 4);
    expect(find.byKey(const ValueKey('home-chip-league')), findsNothing);
    await _done(t);
  });

  testWidgets('verify chip: guest, pending, verified', (t) async {
    await _pump(t, who: _Who.guest);
    expect(find.text('অতিথি'), findsOneWidget);
    expect(find.text('সাইন ইন করুন'), findsOneWidget);
    expect(find.text('⏳ যাচাই চলছে'), findsNothing);
    await _done(t);

    await _pump(t, who: _Who.pending);
    expect(find.text('রহিম মিয়া'), findsOneWidget);
    expect(find.text('⏳ যাচাই চলছে'), findsOneWidget);
    await t.tap(find.text('⏳ যাচাই চলছে'));
    await t.pumpAndSettle();
    expect(find.text('যাচাই অপেক্ষমাণ।'), findsOneWidget, reason: 'pending opens the verify sheet');
    await _done(t);

    await _pump(t, who: _Who.verified);
    expect(find.text('✓ যাচাইকৃত'), findsOneWidget);
    expect(find.text('সাইন ইন করুন'), findsNothing);
    await _done(t);
  });

  testWidgets('a new player starts at L1', (t) async {
    await _pump(t);
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('চলুন, L1'), findsOneWidget);
    await _done(t);
  });

  testWidgets('all open rungs cleared: the friendly state, button to the ladder', (t) async {
    await _pump(t, save: _allCleared());
    expect(find.text('সব খোলা ধাপ শেষ! নতুন মডিউল শীঘ্রই আসছে'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-step')), findsNothing);
    await t.tap(find.text('সিঁড়িতে চলুন'));
    await t.pumpAndSettle();
    expect(_opened, [null]);
    await _done(t);
  });

  for (final size in const [Size(320, 640), Size(360, 740), Size(411, 860), Size(800, 360)]) {
    testWidgets('no overflow and 48 dp targets at ${size.width.toInt()}x${size.height.toInt()}', (t) async {
      await _pump(t, save: _seeded(chest: true), leagueRank: 12, size: size);
      expect(t.takeException(), isNull);
      for (final key in ['home-go', 'home-chip-gift', 'home-chip-league']) {
        final box = t.getRect(find.byKey(ValueKey(key)));
        expect(box.height, greaterThanOrEqualTo(48), reason: '$key tap height');
        expect(box.left, greaterThanOrEqualTo(0), reason: '$key inside the screen');
        expect(box.right, lessThanOrEqualTo(size.width), reason: '$key inside the screen');
        expect(box.bottom, lessThanOrEqualTo(size.height), reason: '$key on screen without scrolling');
      }
      final tool = t.getSize(find.byType(HomeToolboxButton));
      expect(tool.width, greaterThanOrEqualTo(48));
      expect(tool.height, greaterThanOrEqualTo(48));
      final chip = t.getSize(find.ancestor(of: find.text('✓ যাচাইকৃত'), matching: find.byType(SlmPressable)).first);
      expect(chip.height, greaterThanOrEqualTo(48));
      // No horizontal scrolling anywhere on Home.
      final scrollables = t.widgetList<Scrollable>(find.byType(Scrollable));
      expect(scrollables.where((s) => s.axisDirection == AxisDirection.right || s.axisDirection == AxisDirection.left), isEmpty);
      await _done(t);
    });
  }

  testWidgets('an idle Home draws no frames', (t) async {
    await _pump(t, save: _seeded(chest: true), leagueRank: 4);
    await t.pump(const Duration(seconds: 3));
    var frames = 0;
    for (var i = 0; i < 180; i++) {
      if (t.binding.hasScheduledFrame) frames++;
      await t.pump(const Duration(milliseconds: 16));
    }
    debugPrint('PERF Home idle 3 s: frames requested $frames/180');
    expect(frames, 0);
    await _done(t);
  });
}
