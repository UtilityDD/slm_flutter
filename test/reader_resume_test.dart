import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/home/reader/reader_resume.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save, load and clear round-trip per lesson', () async {
    expect(await ReaderResume.load('m1_c2'), isNull);
    final spot = ReaderSpot(phaseIndex: 1, pointIndex: 3, scrollFraction: 0.4);
    await ReaderResume.save('m1_c2', spot);
    expect(await ReaderResume.load('m1_c2'), spot);
    expect(await ReaderResume.load('m1_c3'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reader.resume.m1_c2'), isNotNull);
    await ReaderResume.clear('m1_c2');
    expect(await ReaderResume.load('m1_c2'), isNull);
  });

  test('json round-trip and scroll clamp', () {
    final spot = ReaderSpot(phaseIndex: 2, pointIndex: 0, scrollFraction: 1.7);
    expect(spot.scrollFraction, 1.0);
    expect(ReaderSpot.fromJson(spot.toJson()), spot);
    expect(ReaderSpot(phaseIndex: 0, pointIndex: 0, scrollFraction: -3).scrollFraction, 0.0);
    expect(ReaderSpot(phaseIndex: 0, pointIndex: 0, scrollFraction: double.nan).scrollFraction, 0.0);
  });

  test('corrupt data loads as null', () async {
    const bad = <Object>[
      'not json',
      '[1,2,3]',
      '{"phase":"1","point":2,"scroll":0.1}',
      '{"phase":1}',
      '{"phase":-1,"point":0,"scroll":0}',
      '{"phase":1,"point":2,"scroll":"x"}',
      '',
    ];
    for (final raw in bad) {
      SharedPreferences.setMockInitialValues({'reader.resume.k': raw});
      expect(await ReaderResume.load('k'), isNull, reason: raw.toString());
    }
    // Wrong stored type (an int) must not throw either.
    SharedPreferences.setMockInitialValues({'reader.resume.k': 7});
    expect(await ReaderResume.load('k'), isNull);
  });
}
