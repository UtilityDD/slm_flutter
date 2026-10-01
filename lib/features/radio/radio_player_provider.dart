import 'package:audioplayers/audioplayers.dart';
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
    this.title = 'লাইফস্কিল ও সুরক্ষা রেডিও',
    this.subtitle = 'স্মার্ট লাইনম্যান লাইভ ব্রডকাস্ট • ৯১.২ এফএম',
    this.isVisible = false,
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
  late final AudioPlayer _player;
  static const String _streamUrl = 'https://stream.zeno.fm/f3wvbbqmdg8uv'; // High-reliability live stream fallback

  @override
  RadioState build() {
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        this.state = this.state.copyWith(isPlaying: true, isBuffering: false);
      } else if (state == PlayerState.paused || state == PlayerState.stopped) {
        this.state = this.state.copyWith(isPlaying: false, isBuffering: false);
      }
    });

    ref.onDispose(() {
      _player.dispose();
    });

    return const RadioState();
  }

  Future<void> togglePlay() async {
    try {
      if (state.isPlaying) {
        await _player.pause();
      } else {
        state = state.copyWith(isBuffering: true);
        await _player.play(UrlSource(_streamUrl));
      }
    } catch (_) {
      // Fallback state
      state = state.copyWith(
        isPlaying: !state.isPlaying,
        isBuffering: false,
      );
    }
  }

  void closePlayer() {
    _player.pause();
    state = state.copyWith(isVisible: false, isPlaying: false);
  }

  void showPlayer() {
    state = state.copyWith(isVisible: true);
  }
}

final radioProvider = NotifierProvider<RadioNotifier, RadioState>(RadioNotifier.new);
