import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/network/supabase_service.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Supabase client without halting on network unavailability
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase offline initialization note: $e');
  }

  runApp(const ProviderScope(child: SmartLinemanApp()));
}

class SmartLinemanApp extends StatelessWidget {
  const SmartLinemanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
