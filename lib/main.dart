import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/network/supabase_service.dart';
import 'core/startup/app_memory.dart';
import 'core/startup/startup_trace.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

void main() {
  bootstrap();
  runApp(const ProviderScope(child: SmartLinemanApp()));
}

/// Everything that runs before `runApp`. Nothing here is awaited, so the
/// first frame is not held back (measured by test/perf/startup_perf_test.dart).
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  AppMemory.install();

  // Supabase only restores the saved session from the phone (no network), and
  // the first frame shows "loading" either way. So it starts right after the
  // first frame; AuthNotifier waits for it and gets the restored session from
  // the replaying auth stream. A failure is logged inside: the app runs as guest.
  unawaited(StartupTrace.backgroundStep(
    'supabase',
    () => SupabaseService.initialize(after: _firstFrameShown()),
  ));
}

/// Completes after the first frame, or after 1 s if no frame comes (app
/// started while the screen is off), so sign-in restore is never stuck.
Future<void> _firstFrameShown() {
  final shown = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!shown.isCompleted) shown.complete();
  });
  Timer(const Duration(seconds: 1), () {
    if (!shown.isCompleted) shown.complete();
  });
  return shown.future;
}

class SmartLinemanApp extends StatelessWidget {
  const SmartLinemanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}
