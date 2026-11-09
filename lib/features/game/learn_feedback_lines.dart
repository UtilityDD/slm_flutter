import 'dart:math' as math;

/// One short reaction line. [shownBn] goes in the bubble; [spokenBn] is what
/// the bn-IN voice reads (English words spelled in Bangla so they sound right).
class FeedbackLine {
  const FeedbackLine(this.shownBn, {String? spokenBn, this.voiceKey}) : _spoken = spokenBn;

  final String shownBn;
  final String? _spoken;

  /// Recorded clip in DsVoice, when one exists for this exact line.
  final String? voiceKey;

  String get spokenBn => _spoken ?? shownBn;
}

/// Reaction pools shared by every Learn level. Add lines freely; ids are not
/// stored anywhere, so order and length can change without touching saves.
class LearnFeedbackLines {
  LearnFeedbackLines._();

  /// One short word after a mistake; the reason shows as text (spoken in
  /// full only the first time — see SpokenOnce).
  static const wrong = <FeedbackLine>[
    FeedbackLine('না, হলো না!', voiceKey: 'ds_wrong_holo_na'),
    FeedbackLine('ভুল হলো!', voiceKey: 'ds_wrong_vul_holo'),
    FeedbackLine('উঁহু!'),
    FeedbackLine('আরে না!'),
    FeedbackLine('সাবধান!'),
    FeedbackLine('ধরা খেলেন!'),
    FeedbackLine('উফ্, ফসকে গেল!'),
    FeedbackLine('এটা চলবে না ভাই!'),
  ];

  /// Second mistake in a row on the same question.
  static const wrongAgain = <FeedbackLine>[
    FeedbackLine('আবার!'),
    FeedbackLine('তাড়াহুড়ো নয়!'),
    FeedbackLine('চোখ খোলা রাখুন!'),
    FeedbackLine('থামুন, ভালো করে দেখুন।'),
  ];

  static const right = <FeedbackLine>[
    FeedbackLine('সাবাশ! একদম ঠিক।', voiceKey: 'ds_exp_right_1'),
    FeedbackLine('জব্বর!'),
    FeedbackLine('একদম!'),
    FeedbackLine('খাসা!'),
    FeedbackLine('দারুণ!'),
    FeedbackLine('এই তো চাই!'),
    FeedbackLine('বাজপাখির চোখ!'),
    FeedbackLine('পাকা লাইনম্যান!'),
  ];

  /// After a right pick: ask for the reason.
  static const whyAsk = <FeedbackLine>[
    FeedbackLine('কেন এটা ঠিক?'),
    FeedbackLine('বলুন তো, কেন?'),
    FeedbackLine('কারণটা কী, জানেন?'),
    FeedbackLine('কী কারণে এটা আপনাকে বাঁচাবে?'),
    FeedbackLine('এটাই কেন বেছে নিলেন?'),
    FeedbackLine('এর পেছনের কারণটা বলুন।'),
    FeedbackLine('কেন এটা দরকার, বলতে পারবেন?'),
  ];

  /// After the rival's myth is rejected: ask why it is wrong.
  static const mythWhyAsk = <FeedbackLine>[
    FeedbackLine('একদম ঠিক! কিন্তু ওকে তো বুঝিয়ে বলতে হবে—ওর কথায় কেন ভুল?'),
    FeedbackLine('সাবাশ ওস্তাদ! এবার বলুন তো, কোন কারণে ওর এই কথা বিপদ ডাকে?'),
    FeedbackLine('ঠিক ধরেছেন! কিন্তু ওর এই শর্টকাটটা ভুল কেন, জানিয়ে দিন তো?'),
    FeedbackLine('ওর ফাঁদে পা দেননি, খুব ভালো! এবার আসল নিয়মটা বলুন।'),
  ];

  /// New item to choose.
  static const pickAsk = <FeedbackLine>[
    FeedbackLine('সঠিক জিনিস বেছে নিন'),
    FeedbackLine('এবার কোনটা নেবেন?'),
    FeedbackLine('ঠিক জিনিসটা খুঁজে নিন।'),
    FeedbackLine('কোনটা আপনাকে নিরাপদ রাখবে?'),
  ];

  /// Level below the pass mark.
  static const failed = <FeedbackLine>[
    FeedbackLine('এবার পাস হলো না। পাঠটা দেখে আবার চেষ্টা করুন।'),
    FeedbackLine('আরেকটু বাকি! আবার খেললেই পারবেন।'),
    FeedbackLine('হাল ছাড়বেন না—আরেকবার চেষ্টা করুন।'),
  ];
}

/// Fixed coach lines in the Learn board (all recorded in the coach voice).
abstract final class LearnCoachLines {
  static const notThisReason = 'এই কারণ নয়।';
  static const wrongBelief = 'সর্বনাশ! ওর ফাঁদেই পা দিলেন? ওর কথায় বিশ্বাস করলে যে লাশ হয়ে বাড়ি ফিরতে হবে!';
  static const threeMisses = 'তিনবার ভুল হলো। পাঠটা একবার দেখে নিন।';
  static const rivalComing = 'আরে! ওই দেখুন, শর্টকাট মারার একজন ওস্তাদ এসে জুটেছে!';
  static const realPoint = 'এই তো আসল কথা।';
  static const newRecord = 'নতুন রেকর্ড! আগের চেয়ে দ্রুত।';
  static String badgeEarned(String badge) => '$badge পেয়েছেন। এবার আসল পোশাক পরান।';

  static const all = [notThisReason, wrongBelief, threeMisses, rivalComing, realPoint, newRecord];
}

/// Shuffle bag: every line plays once before any repeats, and the last line
/// of one round never opens the next.
class LineBag {
  LineBag(this.lines, {math.Random? rng}) : _rng = rng ?? math.Random();

  final List<FeedbackLine> lines;
  final math.Random _rng;
  final _queue = <int>[];
  int? _last;

  FeedbackLine next() {
    if (_queue.isEmpty) {
      _queue.addAll(List<int>.generate(lines.length, (i) => i)..shuffle(_rng));
      if (_queue.length > 1 && _queue.first == _last) {
        _queue.add(_queue.removeAt(0));
      }
    }
    final i = _queue.removeAt(0);
    _last = i;
    return lines[i];
  }
}
