import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner decision "Option B" (2026-11-13): the Supabase project is shared with
/// the live web app, so every Android-only database object lives in schema
/// `slm_app` (supabase/slm_app_*.sql) and the web app's objects in `public`
/// are never changed. These are plain text scans of the repo.

/// The app's RPCs. Each must be called as `client.schema('slm_app').rpc(...)`
/// and be defined in an slm_app_*.sql file.
const slmAppRpcs = {
  'submit_level_result',
  'league_board',
  'league_board_all',
  'league_my_wins',
  'my_league_settings',
  'set_league_show_name',
  'toolbox_quiz_question',
  'toolbox_quiz_check',
  'delete_my_account',
  'admin_set_league_hidden',
  'admin_set_approved_name',
};

/// SQL files written before Option B for the web side's `profiles` columns
/// (verified, blocked) and admin functions. They were already run on the
/// shared database; they are web-owned history. Do not add to this list and
/// do not extend these files: new app objects go into slm_app_*.sql.
const legacyWebSql = {
  'admin_access.sql',
  'admin_people_page.sql',
  'block_user.sql',
  'fix_new_google_signup.sql',
  'submit_flutter_hourly_quiz.sql',
  'verify_lineman.sql',
  'verify_toggle.sql',
};

/// The whole lib/ Dart source with all whitespace removed, per file.
Map<String, String> _dartSources() => {
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          f.path.replaceAll(r'\', '/'): f.readAsStringSync().replaceAll(RegExp(r'\s+'), ''),
    };

/// SQL without `--` comments, split into statements.
List<String> _statements(String sql) {
  final noComments = sql.split('\n').map((l) {
    final i = l.indexOf('--');
    return i < 0 ? l : l.substring(0, i);
  }).join('\n');
  return [
    for (final s in noComments.split(';'))
      if (s.trim().isNotEmpty) s.replaceAll(RegExp(r'\s+'), ' ').trim(),
  ];
}

final _alterPublic = RegExp(r'\bALTER TABLE (IF EXISTS )?(ONLY )?"?public"?\.', caseSensitive: false);
final _triggerOnPublic = RegExp(r'\bCREATE (OR REPLACE )?(CONSTRAINT )?TRIGGER\b.*\bON "?public"?\.', caseSensitive: false);
final _policyOnPublic = RegExp(r'\bCREATE POLICY\b.*\bON "?public"?\.', caseSensitive: false);
final _createPublic =
    RegExp(r'\bCREATE (OR REPLACE )?(FUNCTION|VIEW|TABLE|MATERIALIZED VIEW) "?public"?\.', caseSensitive: false);
final _dropPublic = RegExp(r'\bDROP (FUNCTION|VIEW|TABLE|TRIGGER|POLICY)\b.*"?public"?\.', caseSensitive: false);

void main() {
  test('every app RPC goes through the slm_app schema', () {
    final bad = <String>[];
    final seen = <String>{};
    final rpc = RegExp(r'''\.rpc(<[^>]*>)?\(''');
    for (final MapEntry(key: path, value: src) in _dartSources().entries) {
      for (final m in rpc.allMatches(src)) {
        final arg = src.substring(m.end);
        final literal = RegExp(r'''^['"]([a-z0-9_]+)['"]''').firstMatch(arg)?.group(1);
        // Web functions in public (admin panel, hourly quiz) are called as they are.
        if (literal != null && !slmAppRpcs.contains(literal)) continue;
        final before = src.substring(0, m.start);
        if (!before.endsWith(".schema('slm_app')")) {
          bad.add('$path: rpc(${literal ?? arg.substring(0, arg.length.clamp(0, 20))}...)');
        } else {
          seen.add(literal ?? '<dynamic>');
        }
      }
      // Toolbox names go through an injectable helper that calls rpc(fn).
      for (final name in slmAppRpcs) {
        if (src.contains("_rpc('$name'")) seen.add(name);
      }
      // No direct table or view reads of league objects (the tables are closed).
      if (RegExp(r'''\.from\(['"](league_|profiles_public)''').hasMatch(src)) bad.add('$path: .from(league_...)');
    }
    expect(bad, isEmpty, reason: "call these as SupabaseService.client.schema('slm_app').rpc(...)");
    for (final name in ['submit_level_result', 'league_board', 'league_board_all', 'league_my_wins',
        'my_league_settings', 'set_league_show_name', 'delete_my_account', 'toolbox_quiz_question',
        'toolbox_quiz_check']) {
      expect(seen, contains(name), reason: '$name is called by the app (scan found no call)');
    }
    // The toolbox helper itself must use the schema.
    final toolbox = _dartSources()['lib/features/game/toolbox_quiz_sources.dart']!;
    expect(toolbox, contains(".schema('slm_app').rpc(fn,"));
  });

  test('every app RPC is defined in an slm_app SQL file, in schema slm_app', () {
    final sql = [
      for (final f in Directory('supabase').listSync().whereType<File>())
        if (f.uri.pathSegments.last.startsWith('slm_app_') && f.path.endsWith('.sql')) f.readAsStringSync(),
    ].join('\n');
    for (final name in slmAppRpcs) {
      expect(sql, matches(RegExp('FUNCTION slm_app\\.$name\\(')), reason: name);
    }
  });

  test('no SQL file outside HOLD_* changes the web app\'s public objects', () {
    final files = [
      for (final f in Directory('supabase').listSync().whereType<File>())
        if (f.path.endsWith('.sql')) f,
    ];
    expect(files.map((f) => f.uri.pathSegments.last), containsAll(['slm_app_00_schema.sql', 'slm_app_10_league.sql']));
    final hits = <String>[];
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith('HOLD_')) continue;
      final legacy = legacyWebSql.contains(name);
      for (final s in _statements(f.readAsStringSync())) {
        final short = s.length > 90 ? '${s.substring(0, 90)}...' : s;
        // The three hard rules apply to every file except HOLD_* and the
        // already-run web files.
        if (!legacy &&
            (_alterPublic.hasMatch(s) || _triggerOnPublic.hasMatch(s) || _policyOnPublic.hasMatch(s))) {
          hits.add('$name: $short');
        }
        // New files also may not create, replace or drop anything in public.
        if (!legacy && (_createPublic.hasMatch(s) || _dropPublic.hasMatch(s))) hits.add('$name: $short');
      }
    }
    expect(hits, isEmpty, reason: 'Android-only objects belong in schema slm_app');
  });

  test('the old superseded SQL files are gone', () {
    for (final old in ['league.sql', 'league_rungs_seed.sql', 'toolbox_quiz.sql', 'delete_account.sql', 'profiles_privacy.sql']) {
      expect(File('supabase/$old').existsSync(), isFalse, reason: old);
    }
  });
}
