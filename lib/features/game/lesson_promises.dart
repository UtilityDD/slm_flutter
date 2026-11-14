import 'package:flutter/foundation.dart';

/// One habit promise per lesson, taken from that lesson's own `daily_check`
/// lines (`tool/all_training_chapters_bn.json`). Saved by [id] in
/// `GameSave.promises`; the death screen quotes it when the player later dies
/// in that lesson. Ids are stable: never rename one once shipped.
@immutable
class LessonPromise {
  const LessonPromise({required this.id, required this.lessonId, required this.textBn});

  final String id;
  final String lessonId;
  final String textBn;
}

const lessonPromises = <String, LessonPromise>{
  '1.1': LessonPromise(
    id: 'promise/1.1/glove_air_test',
    lessonId: '1.1',
    textBn: 'প্রতিবার পরার আগে গ্লাভসে হাওয়া ভরে এয়ার টেস্ট করব।',
  ),
  '1.2': LessonPromise(
    id: 'promise/1.2/tool_tip_outside',
    lessonId: '1.2',
    textBn: 'হাতের লম্বা টুলের ডগাও লক্ষ্মণ রেখার বাইরে রাখব।',
  ),
  '1.3': LessonPromise(
    id: 'promise/1.3/read_the_pole',
    lessonId: '1.3',
    textBn: 'পোলের গোড়া দেখে, ঠুকে শুনে, তবেই পোলে উঠব।',
  ),
  '1.4': LessonPromise(
    id: 'promise/1.4/harness_check',
    lessonId: '1.4',
    textBn: 'ওঠার আগে হারনেসের স্ট্র্যাপ, সেলাই আর হুক দেখে নেব।',
  ),
  '1.5': LessonPromise(
    id: 'promise/1.5/earth_first',
    lessonId: '1.5',
    textBn: 'আগে মাটিতে আর্থ, তারপর তারে ডিসচার্জ রড—কখনো উল্টো নয়।',
  ),
};

LessonPromise? lessonPromiseFor(String lessonId) => lessonPromises[lessonId];

/// Fixed coach lines around a promise (recorded with the Learn voice pack).
abstract final class PromiseLines {
  static const ask = 'কাজের আগে একটা কথা দিন।';
  static const kept = 'কথা রইল। মাঠে এটাই মনে রাখবেন।';
  static const later = 'ঠিক আছে। পরের বার আবার জিজ্ঞেস করব।';
  static const broken = 'আপনি কথা দিয়েছিলেন';

  static const all = [ask, kept, later];
}
