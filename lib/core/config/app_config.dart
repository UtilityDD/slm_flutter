class AppConfig {
  static const String appName = 'SmartLineman';
  static const String appVersion = '1.0.0';
  static const String websiteUrl = 'https://smartlineman.in';
  static const String websiteOriginWww = 'https://www.smartlineman.in';
  static const String supportEmail = 'support@smartlineman.in';

  /// Google accounts that may open the in-app admin panel. Matched to the session email.
  static const Set<String> adminEmails = {
    'dipnkr.das@gmail.com',
    'roumak.das@gmail.com',
  };

  /// Add this exact value under Supabase → Authentication → URL Configuration → Redirect URLs.
  static const String authRedirectUrl = 'com.smartlineman.app://login-callback';

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
