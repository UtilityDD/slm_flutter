// Settings (MoreScreen): sections in order, the language switch, and the
// delete-account flow against a fake server call (no network).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/core/config/app_config.dart';
import 'package:slm_flutter/core/models/lineman_profile.dart';
import 'package:slm_flutter/features/auth/auth_provider.dart';
import 'package:slm_flutter/features/more/delete_account.dart';
import 'package:slm_flutter/features/more/more_screen.dart';
import 'package:slm_flutter/features/rank/league_board.dart';
import 'package:slm_flutter/features/shell/app_routes.dart';
import 'package:slm_flutter/features/shell/shell_providers.dart';

class _Auth extends AuthNotifier {
  _Auth(this.value);
  final AuthState value;
  var signOuts = 0;

  @override
  AuthState build() => value;

  @override
  Future<void> signOut() async {
    signOuts++;
    state = AuthState(profile: LinemanProfile.guest());
  }
}

const _me = LinemanProfile(
  id: 'u1',
  fullName: 'Real Me',
  role: 'lineman',
  slmId: 'SLM1234',
  district: 'Howrah',
  verified: true,
);

final _member = const AuthState(profile: _me, email: 'me@example.com');
final _admin = AuthState(profile: _me, email: AppConfig.adminEmails.first);
final _guest = AuthState(profile: LinemanProfile.guest());

/// League settings with no network (slm_app.my_league / set_league_show_name).
class _League extends LeagueBoardSource {
  bool showName = true;
  final saved = <bool>[];

  @override
  Future<List<LeagueRow>> month({required bool district}) async => const [];

  @override
  Future<List<LeagueRow>> allTime({required bool district}) async => const [];

  @override
  Future<LeagueMe> myLeague() async => LeagueMe(showName: showName, nameAsked: true);

  @override
  Future<List<LeagueWin>> myWins() async => const [];

  @override
  Future<bool> setShowName(bool value) async {
    saved.add(value);
    showName = value;
    return true;
  }
}

class _Harness {
  late _Auth auth;
  final league = _League();
  var calls = 0;
  final opened = <Uri>[];
  late ProviderContainer container;
}

Future<_Harness> _pump(
  WidgetTester tester,
  AuthState state, {
  Future<Object?> Function()? call,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final h = _Harness();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith(() => h.auth = _Auth(state)),
      myLeagueWinsProvider.overrideWith((ref) async => const <LeagueWin>[]),
      leagueBoardSourceProvider.overrideWithValue(h.league),
      deleteAccountCallProvider.overrideWithValue(() async {
        h.calls++;
        return (call ?? () async => {'success': true})();
      }),
      linkOpenerProvider.overrideWithValue((uri) async => h.opened.add(uri)),
    ],
    child: MaterialApp(
      home: const MoreScreen(),
      onGenerateRoute: (s) => s.name == AppRoutes.login
          ? MaterialPageRoute<void>(settings: s, builder: (_) => const Scaffold(body: Text('LOGIN PAGE')))
          : null,
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  h.container = ProviderScope.containerOf(tester.element(find.byType(MoreScreen)));
  return h;
}

Future<void> _openDeleteDialog(WidgetTester tester) async {
  await tester.tap(find.text('অ্যাকাউন্ট মুছুন'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _waitHold(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  testWidgets('sections in order; obsolete entries gone', (tester) async {
    await _pump(tester, _admin);
    expect(tester.takeException(), isNull);

    const order = [
      'আমার প্রোফাইল',
      'লাইনম্যান লিগ',
      'ভাষা',
      'সরঞ্জাম চিনুন',
      'সার্টিফিকেট',
      'পিপিই',
      'গোপনীয়তা নীতি',
      'অ্যাকাউন্ট মুছুন',
      'লগআউট',
      'অ্যাডমিন',
    ];
    final ys = [for (final l in order) tester.getTopLeft(find.text(l)).dy];
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], greaterThan(ys[i - 1]), reason: '${order[i]} comes after ${order[i - 1]}');
    }
    // Profile tiles and the league switch stay.
    expect(find.text('ফোন'), findsNothing, reason: 'the app no longer asks for or shows a phone number');
    for (final t in ['নাম', 'জেলা', 'ব্লক', 'কাজ', 'বোর্ডে আমার নাম দেখান']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('পরিচিতি'), findsNothing);
    expect(find.text('কুইজ'), findsNothing);
  });

  testWidgets('league name switch saves through slm_app, not the profile', (tester) async {
    final h = await _pump(tester, _member);
    final tile = find.widgetWithText(SwitchListTile, 'বোর্ডে আমার নাম দেখান');
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.league.saved, [false]);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(h.container.read(leagueShowNameProvider).value, isFalse);
  });

  testWidgets('privacy policy opens its URL', (tester) async {
    final h = await _pump(tester, _member);
    await tester.tap(find.text('গোপনীয়তা নীতি'));
    await tester.pump();
    expect(h.opened, [Uri.parse(AppConfig.privacyPolicyUrl)]);
  });

  testWidgets('language switch works from Settings', (tester) async {
    final h = await _pump(tester, _member);
    expect(find.text('সেটিংস'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.container.read(languageProvider), isFalse);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);

    await tester.tap(find.text('বাংলা'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(h.container.read(languageProvider), isTrue);
    expect(find.text('সেটিংস'), findsOneWidget);
  });

  testWidgets('guests see no delete account, no admin, no league', (tester) async {
    await _pump(tester, _guest);
    expect(find.text('অ্যাকাউন্ট মুছুন'), findsNothing);
    expect(find.text('লগআউট'), findsNothing);
    expect(find.text('অ্যাডমিন'), findsNothing);
    expect(find.text('লাইনম্যান লিগ'), findsNothing);
    expect(find.text('ভাষা'), findsOneWidget);
    expect(find.text('সরঞ্জাম চিনুন'), findsOneWidget);
  });

  testWidgets('delete: confirm calls the RPC, signs out, clears the phone, opens login', (tester) async {
    final h = await _pump(tester, _member, prefs: {
      'game_save_v1': '{"points":40}',
      'league_queue_v1': '[]',
      'local_completed_lessons': ['1.1'],
    });
    await _openDeleteDialog(tester);
    expect(find.text('অ্যাকাউন্ট মুছবেন?'), findsOneWidget);
    expect(find.textContaining('চিরতরে'), findsOneWidget);

    // The delete button waits 3 seconds.
    await tester.tap(find.text('হ্যাঁ, মুছুন (3)'));
    await tester.pump();
    expect(h.calls, 0);

    await _waitHold(tester);
    await tester.tap(find.text('হ্যাঁ, মুছুন'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(h.calls, 1);
    expect(h.auth.signOuts, 1);
    expect(h.container.read(authProvider).isAuthenticated, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('local_completed_lessons'), isNull);
    expect(prefs.getString('league_queue_v1'), isNull);
    expect(find.text('LOGIN PAGE'), findsOneWidget);
    expect(find.text('অ্যাকাউন্ট মুছে ফেলা হয়েছে।'), findsOneWidget);
  });

  testWidgets('delete: cancel does nothing', (tester) async {
    final h = await _pump(tester, _member, prefs: {'league_queue_v1': '[]'});
    await _openDeleteDialog(tester);
    await _waitHold(tester);
    await tester.tap(find.text('থাক'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(h.calls, 0);
    expect(h.auth.signOuts, 0);
    expect(find.text('অ্যাকাউন্ট মুছবেন?'), findsNothing);
    expect(h.container.read(authProvider).isAuthenticated, isTrue);
    expect((await SharedPreferences.getInstance()).getString('league_queue_v1'), '[]');
  });

  testWidgets('delete: a server error keeps the account and offers email', (tester) async {
    final h = await _pump(tester, _member, call: () async => throw Exception('offline'));
    await _openDeleteDialog(tester);
    await _waitHold(tester);
    await tester.tap(find.text('হ্যাঁ, মুছুন'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(h.calls, 1);
    expect(h.auth.signOuts, 0);
    expect(find.textContaining(AppConfig.supportEmail), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);

    await tester.tap(find.text('ইমেইল করুন'));
    await tester.pump();
    expect(h.opened.single.scheme, 'mailto');
    expect(h.opened.single.path, AppConfig.supportEmail);

    await tester.tap(find.text('বন্ধ করুন'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.container.read(authProvider).isAuthenticated, isTrue);
    expect(find.text('LOGIN PAGE'), findsNothing);
  });

  testWidgets('delete: admin accounts are refused by the server and stay', (tester) async {
    final h = await _pump(tester, _member, call: () async => {'success': false, 'reason': 'admin_account'});
    await _openDeleteDialog(tester);
    await _waitHold(tester);
    await tester.tap(find.text('হ্যাঁ, মুছুন'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('অ্যাডমিন অ্যাকাউন্ট অ্যাপ থেকে মোছা যায় না।'), findsOneWidget);
    expect(h.auth.signOuts, 0);
  });

  test('reads the RPC reply', () {
    expect(readDeleteReply({'success': true, 'deleted': {}}), DeleteAccountOutcome.deleted);
    expect(readDeleteReply({'success': false, 'reason': 'admin_account'}), DeleteAccountOutcome.adminAccount);
    expect(readDeleteReply({'success': false, 'reason': 'not_signed_in'}), DeleteAccountOutcome.failed);
    expect(readDeleteReply(null), DeleteAccountOutcome.failed);
  });
}
