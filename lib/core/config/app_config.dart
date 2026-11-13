class AppConfig {
  static const String appName = 'SmartLineman';
  static const String websiteUrl = 'https://smartlineman.in';

  /// Where large posters, audio and quiz packs stream from (keeps the APK slim).
  static const String remoteAssetOrigin = 'https://www.smartlineman.in';

  // TODO(owner): host the privacy policy page and put its real URL here
  // (the same URL goes into Play Console → App content → Privacy policy).
  static const String privacyPolicyUrl = 'https://example.com/privacy';

  // TODO(owner): host docs/playstore/account-deletion.html and put its URL here
  // (the same URL goes into Play Console → Data deletion).
  static const String accountDeletionUrl = 'https://example.com/account-deletion';

  // TODO(owner): the support inbox that handles deletion requests by email.
  static const String supportEmail = 'support@example.com';

  /// Google accounts that may open the in-app admin panel. Matched to the session email.
  static const Set<String> adminEmails = {
    'dipnkr.das@gmail.com',
    'roumak.das@gmail.com',
  };

  /// Add this exact value under Supabase → Authentication → URL Configuration → Redirect URLs.
  static const String authRedirectUrl = 'com.smartlineman.lineman://login-callback';

  /// Public web client id. The secret stays in the Supabase dashboard.
  static const String googleWebClientId =
      '1062290108902-3slmum79r57rlf7d2hij7lfdmumjpr2t.apps.googleusercontent.com';

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wkunyvomogeazjwtenck.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndrdW55dm9tb2dlYXpqd3RlbmNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MDIwMDgsImV4cCI6MjA4MTA3ODAwOH0.iY8BjqhUn8rvOwul9a0625LQ_TGmauth5Ltml5mTcR0',
  );
}
