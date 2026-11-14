import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/learn_explainer_videos.dart';

void main() {
  test('lessons 1.1-5.10 have their explainer ids; only the owner-listed gaps stay empty', () {
    expect(LearnExplainerVideos.youtubeIdFor('1.1'), 'gm8u-yXIbZs');
    expect(LearnExplainerVideos.youtubeIdFor('3.10'), 'lzgYwf1rPQU'); // the "final" cut
    expect(LearnExplainerVideos.youtubeIdFor('5.10'), 'oZLotZxzkEQ');
    // No video sent yet for these (owner's list, 2026-11-14).
    const gaps = {'1.4', '2.2', '2.3', '2.5', '2.7', '2.8', '2.9', '2.10'};
    for (var m = 1; m <= 5; m++) {
      for (var n = 1; n <= 10; n++) {
        final id = '$m.$n';
        expect(LearnExplainerVideos.hasVideo(id), !gaps.contains(id), reason: id);
      }
    }
    expect(LearnExplainerVideos.lessonsWithVideo(), hasLength(42));
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
