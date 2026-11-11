import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/learn_explainer_videos.dart';

void main() {
  test('1.1 has the live explainer id; other catalog slots stay empty until filled', () {
    expect(LearnExplainerVideos.youtubeIdFor('1.1'), 'gm8u-yXIbZs');
    expect(LearnExplainerVideos.hasVideo('1.1'), isTrue);
    final empty = [
      for (final m in [1, 2, 3, 4])
        for (var n = 1; n <= 10; n++)
          if (!('$m.$n' == '1.1')) '$m.$n',
    ];
    for (final id in empty) {
      expect(LearnExplainerVideos.hasVideo(id), isFalse, reason: id);
    }
  });

  test('parseVideoId accepts raw ids and common YouTube URLs', () {
    expect(LearnExplainerVideos.parseVideoId('gm8u-yXIbZs'), 'gm8u-yXIbZs');
    expect(
      LearnExplainerVideos.parseVideoId('https://youtu.be/gm8u-yXIbZs?si=6PjUdVdqvsx6jdoP'),
      'gm8u-yXIbZs',
    );
    expect(
      LearnExplainerVideos.parseVideoId('https://www.youtube.com/watch?v=gm8u-yXIbZs&t=12'),
      'gm8u-yXIbZs',
    );
    expect(LearnExplainerVideos.parseVideoId(''), isNull);
  });
}
