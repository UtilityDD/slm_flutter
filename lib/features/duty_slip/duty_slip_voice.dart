import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Pre-rendered human/neural voice player for Duty Slip levels.
/// Gracefully falls back if an asset is not yet recorded.
class DsVoice {
  static final _player = AudioPlayer();
  static var _ready = false;

  static const _audioMap = <String, String>{
    // Level 1: পোশাক
    'লাইনে কাজের সময় পোশাকই প্রথম প্রতিরোধ। শরীরকে সম্পূর্ণ সুরক্ষিত রাখুন।': 'sounds/voice/ds_l1_intro.mp3',
    'কাজে নামার আগে ঠিকঠাক পোশাক বেছে নিন—ঝুঁকি এড়িয়ে সঠিকটা পরান।': 'sounds/voice/ds_l1_start.mp3',
    'না, সাবধান! ঢিলে পোশাক বাতাসে উড়ে লাইনের তারে জড়িয়ে যেতে পারে। শরীর আঁটোসাঁটো রাখা জরুরি।': 'sounds/voice/ds_why_fatua.mp3',
    'থামুন! হাত খোলা থাকলে সামান্য স্পার্কেই সরাসরি চামড়া পুড়ে যাবে। হাত সম্পূর্ণ ঢাকা দরকার।': 'sounds/voice/ds_why_halftee.mp3',
    'মারাত্মক ভুল! আর্ক ফ্ল্যাশের তাপে পলিয়েস্টার গলে চামড়ায় আটকে যাবে। এমন কাপড় বিপজ্জনক।': 'sounds/voice/ds_why_poly.mp3',
    'সাবধান! পা উন্মুক্ত রেখে কাজ করা অনিরাপদ, ধারালো তারের ঘষা লাগতে পারে।': 'sounds/voice/ds_why_halfpant.mp3',
    'না, এটা বিপজ্জনক! ঢিলে পাজামা যন্ত্রাংশে আটকে ভারসাম্য নষ্ট করতে পারে।': 'sounds/voice/ds_why_pajama.mp3',
    'বিপদ! চপ্পলে কোনো গ্রিপ নেই—মই বা পোলে পা হড়কালেই পতন ঘটবে।': 'sounds/voice/ds_why_slip.mp3',
    'না, সতর্ক হোন! সাধারণ জুতোর সোলে বৈদ্যুতিক ইনসুলেশন থাকে না।': 'sounds/voice/ds_why_normal.mp3',
    'আরে আরে, ভুল হচ্ছে! জুতো পরা অবস্থায় প্যান্ট ঠিকমতো পরা সম্ভব নয়। আগে প্যান্টের কাজ শেষ করুন।': 'sounds/voice/ds_block_shoe.mp3',
    'পোশাক নির্বাচন সম্পূর্ণ। শরীর এখন কাজের জন্য সুরক্ষিত।': 'sounds/voice/ds_l1_done.mp3',
    'দারুণ শৃঙ্খলা! পোশাক নির্বাচনে কোনো ত্রুটি হয়নি।': 'sounds/voice/ds_l1_rank_darun.mp3',
    'পোশাক পরা হয়েছে, তবে কাজের সময় আরও সতর্ক থাকা জরুরি।': 'sounds/voice/ds_l1_rank_motamuti.mp3',
    'পোশাক নির্বাচনে ঝুঁকি থেকে গেছে। সতর্কতা বজায় রেখে পুনরায় চেষ্টা করুন।': 'sounds/voice/ds_l1_rank_again.mp3',

    // Right Selection Audio Expressions (Pronunciation fixed)
    'বাহবা! একদম ঠিক।': 'sounds/voice/ds_exp_right_1.mp3',
    'বাঃ, একদম মানানসই!': 'sounds/voice/ds_exp_right_2.mp3',
    'সঠিক নির্বাচন, এগিয়ে চলুন।': 'sounds/voice/ds_exp_right_3.mp3',
    'চমৎকার! এটা ঠিক বসেছে।': 'sounds/voice/ds_exp_right_4.mp3',

    // Level 2: মাথায় হেলমেট
    'মাথার সুরক্ষায় কোনো ছাড় নেই। যেকোনো পতনশীল বস্তু ও বিদ্যুৎস্পর্শ থেকে মাথা রক্ষা করুন।': 'sounds/voice/ds_l2_intro.mp3',
    'লাইনম্যানের সবচেয়ে বড় সুরক্ষা তার হেলমেট। সঠিক সুরক্ষাকবচটি বেছে নিন।': 'sounds/voice/ds_l2_start.mp3',
    'একটু দাঁড়ান! মাথায় কাপড় থাকলে হেলমেট বসবে না, একটু ঝাঁকুনিতেই পড়ে যাবে।': 'sounds/voice/ds_why_gamcha_block.mp3',
    'না, একদম নয়! এটি ট্রাফিকের হেলমেট, হাই-ভোল্টেজ শক আটকানোর ক্ষমতা নেই।': 'sounds/voice/ds_why_road.mp3',
    'বিপজ্জনক! বাতাসের ফুটো দিয়ে লাইনের স্পার্ক বা জল ঢুকলে মাথায় বিদ্যুৎ নামবে। নিশ্ছিদ্র শেল প্রয়োজন।': 'sounds/voice/ds_why_vent.mp3',
    'না দাদা! গামছা কোনো নিরাপত্তা সরঞ্জাম নয়, এটি বিদ্যুৎস্পর্শ আটকাতে পারে না।': 'sounds/voice/ds_why_gamcha_nosave.mp3',
    'মাথা উন্মুক্ত হয়েছে। এবার উপযুক্ত ইলেকট্রিক্যাল হেলমেটটি পরিয়ে দিন।': 'sounds/voice/ds_take_gamcha.mp3',
    'হেলমেট যথাযথভাবে লক করা হয়েছে। মাথার সুরক্ষা নিশ্চিত।': 'sounds/voice/ds_l2_done.mp3',
    'একদম নির্ভুল! মাথার সুরক্ষা সম্পূর্ণ।': 'sounds/voice/ds_l2_rank_darun.mp3',
    'হেলমেট পরা হয়েছে, কিন্তু নির্বাচন নিখুঁত ছিল না।': 'sounds/voice/ds_l2_rank_motamuti.mp3',
    'ভুল হেলমেট মারাত্মক ঝুঁকির কারণ। পুনরায় সঠিকটি নির্বাচন করুন।': 'sounds/voice/ds_l2_rank_again.mp3',

    // Level 3: হাতে গ্লাভস
    'লাইনে কাজ করার সময় হাতই প্রথম ঝুঁকির মুখে পড়ে। লাইভ তার স্পর্শের আগে হাতের সঠিক সুরক্ষা নিশ্চিত করুন।': 'sounds/voice/ds_l3_intro.mp3',
    'হাতে গ্লাভস পরার আগে ত্রুটি ও ইনসুলেশন যাচাই করে সঠিক সুরক্ষাকবচ বেছে নিন।': 'sounds/voice/ds_l3_start.mp3',
    'সাবধান! সুতির কাপড়ে কোনো ইনসুলেশন থাকে না, বিদ্যুৎ স্পর্শ লাগলেই মারাত্মক শক লাগবে।': 'sounds/voice/ds_why_cotton.mp3',
    'থামুন! গ্লাভসে সামান্য আর্দ্রতা বা জল থাকলে তা দিয়ে বিদ্যুৎ শরীরে নেমে আসবে। সম্পূর্ণ শুকনো গ্লাভস আবশ্যক।': 'sounds/voice/ds_why_wet.mp3',
    'বিপজ্জনক! সামান্য সূক্ষ্ম ছিদ্র বা পিনহোল থাকলেও হাই-ভোল্টেজ বিদ্যুৎ সেখান দিয়েই আঘাত করবে। কাজ শুরুর আগে হাওয়া ভরে পরীক্ষা জরুরি।': 'sounds/voice/ds_why_hole.mp3',
    'না, মারাত্মক ঝুঁকি! সাধারণ বাইকের গ্লাভসে বিদ্যুৎ অপরিবাহী স্তর থাকে না, এতে বিদ্যুৎ আটকাবে না।': 'sounds/voice/ds_why_bike.mp3',
    'হাতের গ্লাভস পরা সম্পন্ন হয়েছে। হাত এখন কাজের জন্য প্রস্তুত।': 'sounds/voice/ds_l3_done.mp3',
    'অসাধারণ সতর্কতা! ত্রুটিমুক্ত ইনসুলেটেড গ্লাভস সঠিকভাবে নির্বাচন করেছেন।': 'sounds/voice/ds_l3_rank_darun.mp3',
    'গ্লাভস পরা হয়েছে, তবে কাজের সময় গ্লাভসের ত্রুটি আরও মনোযোগ দিয়ে পরখ করা দরকার।': 'sounds/voice/ds_l3_rank_motamuti.mp3',
    'ত্রুটিযুক্ত গ্লাভসে লাইনে কাজ করা প্রাণঘাতী। সতর্ক হয়ে আবার সঠিক গ্লাভস নির্বাচন করুন।': 'sounds/voice/ds_l3_rank_again.mp3',

    // Level 4: হারনেস
    'উচ্চতায় কাজের সময় পতন রোধে ফুল বডি হারনেসই জীবন বাঁচায়। সঠিক পদ্ধতিতে প্রতিটি বাকল লক করুন।': 'sounds/voice/ds_l4_intro.mp3',
    'উচ্চতায় ওঠায় হারনেসই শেষ ভরসা। গ্লাভস সরিয়ে হারনেস ধরুন এবং ধাপে ধাপে বাঁধুন।': 'sounds/voice/ds_l4_start.mp3',
    'সাবধান! কোমরের সাধারণ বেল্ট পতনজনিত অবস্থায় মেরুদণ্ড ভেঙে দিতে পারে। ওপরের কাজের জন্য ফুল বডি হারনেস আবশ্যক।': 'sounds/voice/ds_why_belt.mp3',
    'থামুন! মোটা গ্লাভস পরে হারনেসের বাকল বা ডি-রিং ঠিকমতো ধরা ও লক করা যায় না। আগে গ্লাভস খুলে নিন।': 'sounds/voice/ds_block_glove.mp3',
    'সাবধান! হারনেসের সুরক্ষায় ধারাবাহিকতা রক্ষা জরুরি। আগের ধাপটি আগে সম্পন্ন করুন।': 'sounds/voice/ds_block_early.mp3',
    'পিঠের ডি-রিং যেন কাঁধের ব্লেডের ঠিক মাঝখানে থাকে, অবস্থান যাচাই করুন।': 'sounds/voice/ds_step_ring.mp3',
    'পিঠের রিং ধরে হাতের কাছে তুলুন।': 'sounds/voice/ds_step_palm.mp3',
    'হারনেস সামনে আছে। আগে গ্লাভস খুলুন।': 'sounds/voice/ds_park_glove.mp3',
    'তালিকার সঠিক ধাপটি নির্বাচন করে এগিয়ে চলুন।': 'sounds/voice/ds_step_tap.mp3',
    'হারনেসের সমস্ত বাকল যথাযথ লক হয়েছে এবং দুই আঙুলের ছাড় ঠিক আছে। উচ্চতায় কাজের সুরক্ষা নিশ্চিত।': 'sounds/voice/ds_l4_done.mp3',
    'নিখুঁত কাজ! হারনেস সঠিকভাবে বাঁধা হয়েছে এবং দুই আঙুলের উপযুক্ত ফাঁক রয়েছে।': 'sounds/voice/ds_l4_rank_darun.mp3',
    'হারনেস পরা হয়েছে, তবে কাজের সময় বাকল ও ফিতার টান আরও নিশ্ছিদ্র হওয়া প্রয়োজন।': 'sounds/voice/ds_l4_rank_motamuti.mp3',
    'আলগা বা ভুলভাবে বাঁধা হারনেসে পতন ঘটলে মারাত্মক জখম হতে পারে। পুনরায় সঠিক নিয়মে বাঁধুন।': 'sounds/voice/ds_l4_rank_again.mp3',
  };

  static Future<bool> play(String text, {bool muted = false}) async {
    if (muted) return true;
    final file = _audioMap[text.trim()];
    if (file == null) return false;
    try {
      if (!_ready) {
        _ready = true;
        await _player.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
        );
      }
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.stop);

      final c = Completer<void>();
      late StreamSubscription sub;
      sub = _player.onPlayerComplete.listen((_) {
        sub.cancel();
        if (!c.isCompleted) c.complete();
      });

      await _player.play(AssetSource(file));
      await c.future.timeout(const Duration(seconds: 12), onTimeout: () => sub.cancel());
      return true;
    } catch (_) {
      return false;
    }
  }

  static void stop() {
    try {
      _player.stop();
    } catch (_) {}
  }
}
