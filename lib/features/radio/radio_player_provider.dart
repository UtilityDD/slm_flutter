import 'package:flutter_riverpod/flutter_riverpod.dart';

class RadioState {
  final bool isPlaying;
  final bool isBuffering;
  final String title;
  final String subtitle;
  final bool isVisible;

  const RadioState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.title = 'লাইফস্কিল ও নিরাপত্তা রেডিও',
    this.subtitle = 'স্মার্ট লাইনম্যান লাইভ ব্রডকাস্ট • ৯১.২ এফএম',
    this.isVisible = true,
  });

  RadioState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    String? title,
    String? subtitle,
    bool? isVisible,
  }) {
    return RadioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class RadioNotifier extends Notifier<RadioState> {
  @override
  RadioState build() => const RadioState();

  void togglePlay() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void closePlayer() {
    state = state.copyWith(isVisible: false, isPlaying: false);
  }

  void showPlayer() {
    state = state.copyWith(isVisible: true);
  }
}

final radioProvider = NotifierProvider<RadioNotifier, RadioState>(RadioNotifier.new);
