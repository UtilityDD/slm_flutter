import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` when the UI is Bengali, matching the web `language === 'bn'` default.
class LanguageNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setBengali(bool value) => state = value;
}

final languageProvider = NotifierProvider<LanguageNotifier, bool>(LanguageNotifier.new);

class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, int>(ShellTabNotifier.new);

String tr(bool bn, String bangla, String english) => bn ? bangla : english;
