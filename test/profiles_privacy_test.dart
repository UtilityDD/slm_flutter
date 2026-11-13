import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `supabase/profiles_privacy.sql` lets a member read only their own
/// `profiles` row (admins: every row). Other people's names, districts and
/// points come from the `profiles_public` view or the league functions.
/// A new direct `profiles` read anywhere else would either break or, if the
/// policy were loosened again, leak phone numbers and emails.
void main() {
  test('only own-row and admin code reads the profiles table', () {
    const allowed = {
      'lib/features/auth/auth_provider.dart', // own row (id = auth.uid())
      'lib/features/more/profile_edit.dart', // own row update
      'lib/features/home/lesson_reader_page.dart', // own row update
      'lib/features/admin/admin_screen.dart', // admins only (is_admin policy)
    };
    final direct = RegExp(r'''\.from\(\s*['"]profiles['"]\s*\)''');
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      if (direct.hasMatch(f.readAsStringSync())) hits.add(path);
    }
    expect(hits, isEmpty, reason: 'Read other people through profiles_public or an RPC.');
  });

  test('the public view the app reads is defined in the SQL', () {
    final board = File('lib/features/quizzes/leaderboard_provider.dart').readAsStringSync();
    expect(board, contains("'profiles_public'"));
    final sql = File('supabase/profiles_privacy.sql').readAsStringSync();
    expect(sql, contains('CREATE VIEW public.profiles_public'));
    final view = sql.substring(sql.indexOf('CREATE VIEW public.profiles_public'));
    final body = view.substring(0, view.indexOf(';'));
    for (final secret in ['phone', 'email', 'block ', 'p.block,', 'job', 'role']) {
      expect(body.contains(secret), isFalse, reason: 'profiles_public must not expose $secret');
    }
  });
}
