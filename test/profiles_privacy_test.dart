import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `supabase/HOLD_profiles_privacy.sql` (ON HOLD, not run: it would change
/// the web app's `profiles` policies) would let a member read only their own
/// `profiles` row (admins: every row). The app is written for that day
/// already: other people's names, districts and points come only from the
/// SECURITY DEFINER functions in schema `slm_app` (league board), never from
/// a direct `profiles` read and never from the HOLD file's `profiles_public`.
/// A new direct `profiles` read anywhere else would either break or, if the
/// policy stayed loose, leak phone numbers and emails.
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
    expect(hits, isEmpty, reason: 'Read other people through an slm_app RPC.');
  });

  test('the privacy SQL is on hold and nothing in the app depends on it', () {
    expect(File('supabase/profiles_privacy.sql').existsSync(), isFalse, reason: 'renamed to HOLD_profiles_privacy.sql');
    final sql = File('supabase/HOLD_profiles_privacy.sql').readAsStringSync();
    expect(sql.substring(0, 400), contains('DO NOT RUN THIS FILE'));

    // profiles_public is created only by the HOLD file, so no app code may read it.
    final readers = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains('profiles_public')) readers.add(f.path.replaceAll(r'\', '/'));
    }
    expect(readers, isEmpty, reason: 'profiles_public does not exist on the server; use slm_app.league_board');

    // If it is ever run, its public view must still hide the private columns.
    final view = sql.substring(sql.indexOf('CREATE VIEW public.profiles_public'));
    final body = view.substring(0, view.indexOf(';'));
    for (final secret in ['phone', 'email', 'block ', 'p.block,', 'job', 'role']) {
      expect(body.contains(secret), isFalse, reason: 'profiles_public must not expose $secret');
    }
  });
}
