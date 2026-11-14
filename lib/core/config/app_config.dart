class AppConfig {
  static const String appName = 'SmartLineman';
  static const String websiteUrl = 'https://smartlineman.in';

  /// Where large posters, audio and quiz packs stream from (keeps the APK slim).
  static const String remoteAssetOrigin = 'https://www.smartlineman.in';

  // TODO(owner): host the privacy policy page and put its real URL here
  // (the same URL goes into Play Console → App content → Privacy policy).
  static const String privacyPolicyUrl = 'https://smartlinemanapp.github.io/privacy_policy/smartlineman.html';

  // TODO(owner): host docs/playstore/account-deletion.html and put its URL here
  // (the same URL goes into Play Console → Data deletion).
  static const String accountDeletionUrl = 'https://smartlinemanapp.github.io/privacy_policy/account-deletion.html';

  // TODO(owner): the support inbox that handles deletion requests by email.
  static const String supportEmail = 'smartlinemanapp@gmail.com';

  /// Google accounts that may open the in-app admin panel. Matched to the session email.
  /// The server has the same two emails: `slm_app.is_admin()` and the league /
  /// delete-account functions (supabase/slm_app_00_schema.sql, slm_app_10_league.sql,
  /// slm_app_30_delete_account.sql) and the web side's admin_* functions. Change them together.
  static const Set<String> adminEmails = {
    'dipnkr.das@gmail.com',
    'roumak.das@gmail.com',
  };

  /// Add this exact value under Supabase → Authentication → URL Configuration → Redirect URLs.
  static const String authRedirectUrl = 'com.smartlineman.lineman://login-callback';

  /// Public web client id. The secret stays in the Supabase dashboard.
  static const String googleWebClientId =
      '1062290108902-3slmum79r57rlf7d2hij7lfdmumjpr2t.apps.googleusercontent.com';

  // Supabase Configuration. The project is shared with the website: app-only
  // database objects live in the `slm_app` schema (supabase/README.md), and
  // app RPCs are called as client.schema('slm_app').rpc(...).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wkunyvomogeazjwtenck.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrdW55dm9tb2dlYXpqd3RlbmNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MDIwMDgsImV4cCI6MjA4MTA3ODAwOH0.iY8BjqhUn8rvOwul9a0625LQ_TGmauth5Ltml5mTcR0',
  );
}
