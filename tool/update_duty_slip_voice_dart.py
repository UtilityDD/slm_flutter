"""
Update Duty Slip Voice Dart (duty_slip_voice.dart)
Generates the Flutter voice playback map from the neural MP3 catalog and the
fallback sentences below. Only sentences that still occur in lib/ Dart code or
assets/data JSON are emitted; re-run after copy edits. Run from the repo root.
"""

import glob
import os
import sys
import json

sys.stdout.reconfigure(encoding='utf-8')

CATALOG_PATH = "tool/game_voice_catalog.json"
TARGET_DART = "lib/features/duty_slip/duty_slip_voice.dart"

with open(CATALOG_PATH, "r", encoding="utf-8") as f:
    catalog = json.load(f)

# Legacy / variant mappings to prevent any missed speech
LEGACY_VARIANTS = {
    # Bamboo ladder
    "আরে, বাঁশের মই নিয়ে উঠবেন না। ভিজলে পা হড়কায়, হঠাৎ ভেঙেও যায়।": "sounds/voice/ds_l7_bamboo.mp3",
    "আরে, বাঁশের মই নিয়ে রাতে উঠবেন না। ভিজলে পা হড়কায়, অন্ধকারে দেখাও যায় না।": "sounds/voice/ds_l7_bamboo.mp3",
    # Belt
    "কোমরের বেল্টে ঝুললে শরীর উল্টে যায়। খুঁটিতে ফুল-বডি হারনেস লাগবে।": "sounds/voice/ds_l7_belt.mp3",
    "না, এটা বিপজ্জনক! কোমরের বেল্ট প্যানেলের হাতলে আটকে যেতে পারে। এই ঘরে বেল্ট নয়।": "sounds/voice/ds_why_belt.mp3",
    # Road Helmet variants
    "এটা রাস্তার হেলমেট। খুঁটির কাজে এতে মাথা বাঁচবে না।": "sounds/voice/ds_why_road.mp3",
    "এটা রাস্তার হেলমেট। বুশিংয়ের কাজে এতে মাথা বাঁচবে না।": "sounds/voice/ds_why_road.mp3",
    "এটা রাস্তার হেলমেট। রাতের লাইনে এতে মাথা বাঁচবে না।": "sounds/voice/ds_why_road.mp3",
    "এটা রাস্তার হেলমেট। ডালের কাজে এতে মাথা বাঁচবে না।": "sounds/voice/ds_why_road.mp3",
    # Vented Helmet variants
    "ফুটো হেলমেট নিয়ে খুঁটিতে উঠবেন না। ফুলকি বা জল ঢুকে যাবে।": "sounds/voice/ds_why_vent.mp3",
    "ফুটো হেলমেট নিয়ে বুশিং খুলবেন না। ফুলকি ঢুকে যাবে।": "sounds/voice/ds_why_vent.mp3",
    "ফুটো হেলমেট নিয়ে বৃষ্টিতে উঠবেন না। জল ঢুকে যাবে।": "sounds/voice/ds_why_vent.mp3",
    "ফুটো হেলমেট নিয়ে ডালের কাছে যাবেন না। ফুলকি ঢুকে যাবে।": "sounds/voice/ds_why_vent.mp3",
    # Gamcha variants
    "গামছা মাথায় জড়ালে হেলমেট বসবে না। এতে বিদ্যুৎও আটকায় না।": "sounds/voice/ds_why_gamcha_nosave.mp3",
    "গামছা মাথায় জড়ালে হেলমেট বসবে না। বুশিংয়ের আগুনও আটকায় না।": "sounds/voice/ds_why_gamcha_nosave.mp3",
    "গামছা মাথায় জড়ালে হেলমেট বসবে না। রাতে গাড়িও আপনাকে দেখবে না।": "sounds/voice/ds_why_gamcha_nosave.mp3",
    # Cotton gloves variants
    "সুতির গ্লাভসে বিদ্যুৎ আটকায় না। রাবারের গ্লাভস রাখুন।": "sounds/voice/ds_why_cotton.mp3",
    # Wet gloves variants
    "গ্লাভস ভেজা। ভেজা গ্লাভস দিয়ে বিদ্যুৎ হাতে চলে আসে।": "sounds/voice/ds_why_wet.mp3",
    # Pinhole / hole variants
    "এই গ্লাভসে ফুটো। ফুটো দিয়েই শক লাগে।": "sounds/voice/ds_why_hole.mp3",
    # Bike gloves variants
    "বাইকের গ্লাভসে বিদ্যুৎ আটকায় না।": "sounds/voice/ds_why_bike.mp3",
    # Fatua variants
    "ফতুয়া হাওয়ায় উড়ে তারে জড়িয়ে যাবে। সুতির শার্ট রাখুন।": "sounds/voice/ds_why_fatua.mp3",
    "ফতুয়া হাওয়ায় উড়ে বুশিংয়ে জড়িয়ে যাবে। সুতির শার্ট রাখুন।": "sounds/voice/ds_why_fatua.mp3",
    "ফতুয়া হাওয়ায় উড়ে ডালে জড়িয়ে যাবে। সুতির শার্ট রাখুন।": "sounds/voice/ds_why_fatua.mp3",
    "না, সাবধান! ঢিলে পোশাক প্যানেলের হাতলে জড়িয়ে যেতে পারে। শরীর আঁটোসাঁটো রাখা জরুরি।": "sounds/voice/ds_why_fatua.mp3",
    # Half tee variants
    "হাতা ছোট। তারের ছ্যাঁকা সোজা গায়ে লাগবে।": "sounds/voice/ds_why_halftee.mp3",
    "হাতা ছোট। আর্কের ছ্যাঁকা সোজা গায়ে লাগবে।": "sounds/voice/ds_why_halftee.mp3",
    "হাতা ছোট। ডালের ঘষা সোজা গায়ে লাগবে।": "sounds/voice/ds_why_halftee.mp3",
    # Polyester variants
    "পলিয়েস্টার গলে গায়ে লেগে যায়। সুতির শার্ট রাখুন।": "sounds/voice/ds_why_poly.mp3",
    # Pajama variants
    "ঢিলে পাজামায় পা জড়িয়ে মই থেকে পড়ে যাবেন।": "sounds/voice/ds_why_pajama.mp3",
    "ঢিলে পাজামা যন্ত্রাংশে জড়িয়ে যাবে।": "sounds/voice/ds_why_pajama.mp3",
    "ঢিলে পাজামা ডালে জড়িয়ে যাবে।": "sounds/voice/ds_why_pajama.mp3",
    # Halfpant variants
    "হাফ প্যান্টে পা খোলা। তারের ঘষা সোজা গায়ে লাগবে।": "sounds/voice/ds_why_halfpant.mp3",
    "হাফ প্যান্টে পা খোলা। আর্কের আগুন সোজা গায়ে লাগবে।": "sounds/voice/ds_why_halfpant.mp3",
    "হাফ প্যান্টে পা খোলা। ডালের ঘষা সোজা গায়ে লাগবে।": "sounds/voice/ds_why_halfpant.mp3",
    "সাবধান! পা উন্মুক্ত রেখে কাজ করা অনিরাপদ, আর্কের আগুন সরাসরি চামড়ায় লাগবে।": "sounds/why_halfpant.mp3",
    # Slipper variants
    "চপ্পল পরে মইয়ে উঠবেন না। পা হড়কালেই পড়ে যাবেন।": "sounds/voice/ds_why_slip.mp3",
    "চপ্পল পরে বুশিংয়ের কাছে যাবেন না। পা হড়কাবে, বিদ্যুৎও আটকাবে না।": "sounds/voice/ds_why_slip.mp3",
    "চপ্পল পরে রাতের রাস্তায় উঠবেন না। পা হড়কালেই পড়ে যাবেন।": "sounds/voice/ds_why_slip.mp3",
    "চপ্পল পরে ভেজা মাটিতে ডাল নামানো যাবে না। পা হড়কালেই পড়ে যাবেন।": "sounds/voice/ds_why_slip.mp3",
    "বিপদ! চপ্পলে কোনো ইনসুলেশন নেই। স্পার্ক লাগলে পা বাঁচবে না।": "sounds/voice/ds_why_slip.mp3",
    # Normal shoe variants
    "সাধারণ জুতোয় বিদ্যুৎ আটকায় না, মইয়ে পাও হড়কায়। সেফটি বুট রাখুন।": "sounds/voice/ds_why_normal.mp3",
    "সাধারণ জুতোয় বিদ্যুৎ আটকায় না। সেফটি বুট রাখুন।": "sounds/voice/ds_why_normal.mp3",
    "সাধারণ জুতোয় বিদ্যুৎ আটকায় না, ভেজা রাস্তায় পাও হড়কায়। সেফটি বুট রাখুন।": "sounds/voice/ds_why_normal.mp3",
    # Tree cutting tools
    "লাইন মৃত না করে করাত দিয়ে ডাল কাটবেন না।": "sounds/voice/ds_l10_sickle.mp3",
    # Level 12 & 13 inspection report warnings
    "গোড়ার ঘাস সরিয়ে ফাটলটা না দেখে রিপোর্ট করবেন না।": "sounds/voice/ds_l11_miss_grass.mp3",
    "স্টে-তার দেখে নিন, তারপর রিপোর্ট করুন।": "sounds/voice/ds_l11_miss_stay.mp3",
    "পেছনে রড বেরিয়েছে কি না না দেখে রিপোর্ট করবেন না।": "sounds/voice/ds_l11_miss_back.mp3",
    "হাতুড়ি ঠুকে শব্দ না শুনে রিপোর্ট করবেন না।": "sounds/voice/ds_l11_miss_hammer.mp3",
    "স্টিল পোলের আসল শত্রু মাটির সংযোগস্থলের মরিচা। গোড়াটা পরিষ্কার করে দেখলেন না?": "sounds/voice/ds_l13_ok_base.mp3",
    "স্টিলের পোলে হাতুড়ি ঠুকে টন টন শব্দটা যাচাই করলেন না?": "sounds/voice/ds_l13_ok_hammer.mp3",
    "চারপাশ ঘুরে ওয়েল্ডিং জয়েন্ট আর ক্ল্যাম্পগুলো দেখলেন না?": "sounds/voice/ds_l13_ok_back.mp3",
    "গোড়া থেকে ওপর পর্যন্ত চোখ বুলিয়ে ক্রস-আর্ম আর ইনসুলেটর দেখলেন না?": "sounds/voice/ds_l13_ok_top.mp3",
}

BN_DIGITS = str.maketrans("০১২৩৪৫৬৭৮৯", "0123456789")


def _json_strings(node, out):
    if isinstance(node, str):
        out.append(node)
    elif isinstance(node, dict):
        for v in node.values():
            _json_strings(v, out)
    elif isinstance(node, list):
        for v in node:
            _json_strings(v, out)


def live_corpus():
    """Text that DsVoice.play() can receive: app Dart code and data JSON.

    play() is always called with a full (filled, English-digit) sentence, so a
    map key is only useful if that sentence occurs here. Cue ids are never
    looked up.
    """
    parts = []
    for path in glob.glob("lib/**/*.dart", recursive=True):
        if os.path.normpath(path) == os.path.normpath(TARGET_DART):
            continue
        with open(path, "r", encoding="utf-8") as f:
            parts.append(f.read())
    for path in glob.glob("assets/data/**/*.json", recursive=True):
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        parts.append(text)
        strings = []
        _json_strings(json.loads(text), strings)
        parts.extend(strings)
    corpus = "\n".join(parts)
    return corpus + "\n" + corpus.translate(BN_DIGITS)


def generate_dart_file():
    corpus = live_corpus()
    seen = set()

    def entry(key, mp3):
        if key in seen or key not in corpus:
            return None
        seen.add(key)
        return f"    '{key}': '{mp3}',"

    lines = []
    lines.append("// GENERATED FILE - DO NOT EDIT MANUALLY")
    lines.append("// SLM Game Voice Library (স্মার্ট লাইনম্যান গেম অডিও লাইব্রেরি)")
    lines.append("// Engine: Microsoft Edge Neural (bn-IN-BashkarNeural)")
    lines.append("// Generated by tool/update_duty_slip_voice_dart.py")
    lines.append("")
    lines.append("import 'dart:async';")
    lines.append("import 'package:audioplayers/audioplayers.dart';")
    lines.append("")
    lines.append("/// Centralized voice player for Duty Slip / Mrityuhin Poth game levels.")
    lines.append("/// Plays authentic high-quality pre-synthesized neural Bengali audio cues.")
    lines.append("class DsVoice {")
    lines.append("  static final _player = AudioPlayer();")
    lines.append("  static var _ready = false;")
    lines.append("")
    lines.append("  static const _audioMap = <String, String>{")

    count = 0
    # Add from catalog
    for lvl_key, lvl_info in catalog.items():
        lines.append(f"    // =========================================================")
        lines.append(f"    // {lvl_info['title']}")
        lines.append(f"    // =========================================================")
        for cue_name, cue_data in lvl_info["cues"].items():
            mp3_path = f"sounds/voice/{cue_name}.mp3"
            new_text = cue_data["text"]
            old_text = cue_data.get("old", "")

            # Authentic Bengali text lookup, then the old text (if distinct).
            # Only sentences the app can still say are emitted.
            for key in (new_text, old_text):
                line = entry(key, mp3_path) if key else None
                if line:
                    lines.append(line)
                    count += 1
        lines.append("")

    lines.append("    // =========================================================")
    lines.append("    // LEGACY & VARIANT CONTEXT STRINGS (FALLBACK)")
    lines.append("    // =========================================================")
    for k, v in LEGACY_VARIANTS.items():
        line = entry(k, v)
        if line:
            lines.append(line)

    lines.append("  };")
    lines.append("")
    lines.append("  /// Plays the audio track corresponding to the provided text or cue key.")
    lines.append("  static Future<bool> play(String text, {bool muted = false}) async {")
    lines.append("    if (muted) return true;")
    lines.append("    final file = _audioMap[text.trim()];")
    lines.append("    if (file == null) return false;")
    lines.append("    try {")
    lines.append("      if (!_ready) {")
    lines.append("        _ready = true;")
    lines.append("        await _player.setAudioContext(")
    lines.append("          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),")
    lines.append("        );")
    lines.append("      }")
    lines.append("      await _player.stop();")
    lines.append("      await _player.setVolume(1.0);")
    lines.append("      await _player.setReleaseMode(ReleaseMode.stop);")
    lines.append("")
    lines.append("      final c = Completer<void>();")
    lines.append("      late StreamSubscription sub;")
    lines.append("      sub = _player.onPlayerComplete.listen((_) {")
    lines.append("        sub.cancel();")
    lines.append("        if (!c.isCompleted) c.complete();")
    lines.append("      });")
    lines.append("")
    lines.append("      await _player.play(AssetSource(file));")
    lines.append("      await c.future.timeout(const Duration(seconds: 14), onTimeout: () => sub.cancel());")
    lines.append("      return true;")
    lines.append("    } catch (_) {")
    lines.append("      return false;")
    lines.append("    }")
    lines.append("  }")
    lines.append("")
    lines.append("  /// Stops current speech playback immediately.")
    lines.append("  static void stop() {")
    lines.append("    try {")
    lines.append("      _player.stop();")
    lines.append("    } catch (_) {}")
    lines.append("  }")
    lines.append("}")
    lines.append("")

    dart_content = "\n".join(lines)
    with open(TARGET_DART, "w", encoding="utf-8") as f:
        f.write(dart_content)
    print(f"Generated {TARGET_DART} with {count} live catalog lines and {len(seen) - count} live fallbacks.")

if __name__ == "__main__":
    generate_dart_file()
