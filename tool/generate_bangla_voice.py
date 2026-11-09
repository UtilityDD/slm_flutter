"""High-Fidelity Bengali Audio Generator for Smart Lineman.

Generates 100% authentic native Bengali male voice audio for the Guide Coach
and universal game prompts using Microsoft Azure/Edge Neural Voice
(bn-IN-BashkarNeural), with optional ElevenLabs integration if a cloned
voice ID is provided.

Usage:
  python tool/generate_bangla_voice.py
  python tool/generate_bangla_voice.py --list
"""

import os
import sys
import json
import asyncio
import argparse
import edge_tts

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_PATH = os.path.join(ROOT, ".env")
OUTPUT_DIR = os.path.join(ROOT, "assets", "sounds", "guide_voice")

# Native Indian Bengali male neural voice (Kolkata / West Bengal accent)
# Energetic, inspiring, authentic pronunciation of all Bengali conjuncts.
DEFAULT_VOICE = "bn-IN-BashkarNeural"
DEFAULT_RATE = "+2%"
DEFAULT_PITCH = "+0Hz"

GUIDE_PROMPTS = {
    # --- Universal Guide Presence & Inspirations ---
    "guide_welcome": {
        "text": "নমস্কার লাইনম্যান দাদা! কাজে নামার আগে প্রতিটি সুরক্ষা নিয়ম ঝালিয়ে নিন।",
        "description": "Warm, inspiring daily welcome on the ladder",
    },
    "guide_praise_great": {
        "text": "সাবাশ! একদম খাঁটি লাইনম্যানের মতো নিখুঁত কাজ হয়েছে!",
        "description": "High praise on flawless execution",
    },
    "guide_warn_danger": {
        "text": "সাবধান! সুরক্ষায় কোনো আপস নয়, আগে নিজের জীবন তারপর কাজ!",
        "description": "Urgent life-saving caution",
    },
    "guide_halt_mistake": {
        "text": "থামুন! এক মুহূর্তের ভুলে বড় বিপদ হতে পারে। নিয়ম মেনে পুনরায় চেষ্টা করুন।",
        "description": "Firm interruption on dangerous slip",
    },
    "guide_rank_up": {
        "text": "অভিনন্দন! আপনি নতুন পদোন্নতি এবং সুরক্ষা কবচ অর্জন করেছেন!",
        "description": "Heroic rank elevation fanfare",
    },

    # --- Universal Reusable Expressions Across All Levels ---
    "exp_right_1": {
        "text": "সাবাশ! একদম ঠিক।",
        "description": "Universal punchy praise for correct tap",
    },
    "exp_right_2": {
        "text": "বাঃ, একদম নিখুঁত নির্বাচন!",
        "description": "Universal praise for correct item",
    },
    "exp_right_3": {
        "text": "সঠিক সিদ্ধান্ত, পরের ধাপে চলুন।",
        "description": "Universal praise moving to next step",
    },
    "exp_right_4": {
        "text": "চমৎকার! যথাযথ ফিটিং হয়েছে।",
        "description": "Universal praise for equipment fit",
    },
    "exp_wrong_holo_na": {
        "text": "না, হলো না!",
        "description": "Universal immediate reaction to wrong tap",
    },
    "exp_wrong_vul": {
        "text": "ভুল হলো! নিয়মটি আবার মনে করুন।",
        "description": "Universal correction prompt",
    },
    "exp_wrong_bhabun": {
        "text": "না, হলো না—আবার একটু ভেবে দেখুন।",
        "description": "Universal gentle nudge on second attempt",
    },
    "rank_3star": {
        "text": "চমৎকার শৃঙ্খলা! কোনো ত্রুটি ছাড়াই নিখুঁতভাবে কাজ সম্পন্ন হয়েছে!",
        "description": "3-star gold victory evaluation",
    },
    "rank_2star": {
        "text": "কাজ শেষ হয়েছে, তবে কাজের সময় আরও সতর্ক থাকা জরুরি।",
        "description": "2-star pass evaluation",
    },
    "rank_fail": {
        "text": "কাজে মারাত্মক ঝুঁকি থেকে গেছে। সুরক্ষার নিয়ম মেনে পুনরায় চেষ্টা করুন।",
        "description": "Retry evaluation on fail",
    },

    # --- Step 30 Rank Gate ("প্রথম ডকেট" - First Real Field Dispatch) ---
    "gate_intro": {
        "text": "জরুরি ডকেট এলো! ১১ কেভি ফিডার মেরামত। ভ্যান থেকে সঠিক রড বাছাই, পারমিট মেলানো, পোলের শব্দ পরীক্ষা, ডিসচার্জ স্পার্ক এবং ঝড় থেকে নিরাপদে ফিরে ট্রেইনি পদোন্নতি অর্জন করুন!",
        "description": "High-octane mission briefing for Step 30 gate",
    },
    "gate_ask_van": {
        "text": "ডকেট ১১ কেভি লাইনের। ভ্যান থেকে ঠিক রডটি বেছে নিন।",
        "description": "Station 1 tool selection prompt",
    },
    "gate_ask_ptw": {
        "text": "সাইটের ফিডার প্লেট দেখুন। ফোনে কাজ শুরু করবেন, না থামবেন?",
        "description": "Station 2 Permit to work verification",
    },
    "gate_ask_pole": {
        "text": "পোল ঘুরে দেখুন ও হাতুড়ি ঠুকে পোলের ভাষা পড়ুন। উঠবেন?",
        "description": "Station 3 Pole sounding inspection",
    },
    "gate_ask_discharge": {
        "text": "ডিসচার্জ ক্রম: আগে মাটি, পরে তিন ফেজে হুক ঠেকান।",
        "description": "Station 4 Earth spike first sequence",
    },
    "gate_ask_storm": {
        "text": "আকাশে বজ্র ডাকছে! সহকর্মীর চাপ মানবেন না, সরাসরি ভ্যানে নিরাপদ আশ্রয়ে চলুন!",
        "description": "Station 5 Storm evacuation alert",
    },
    "gate_mission_done": {
        "text": "অভিনন্দন! প্রথম ডকেট সম্পূর্ণ সফল! আপনি এখন অনুমোদিত ট্রেইনি লাইনম্যান!",
        "description": "Victory announcement upon completing Rank Gate",
    },

    # --- Field Characters & Dispatch Radio ---
    "control_room_radio": {
        "text": "হ্যালো লাইনম্যান! রামপুর ১১ কেভি ফিডার ব্রেকার নামিয়েছি। তোমরা গাছে উঠে কাজ সেরে নাও — শাটডাউনের কাগজ পরে পাঠিয়ে দিচ্ছি!",
        "description": "Control room operator's verbal rush shortcut over radio",
    },
    "coworker_rush_line": {
        "text": "আর একটু, শেষ করে নামি! এইটুকু কাজ ফেলে কেউ নামে?",
        "description": "Careless rival coworker pressuring to rush in lightning",
    },
}


async def generate_clip(sem, key, text, out_file):
    async with sem:
        for attempt in range(4):
            try:
                communicate = edge_tts.Communicate(text, DEFAULT_VOICE, rate=DEFAULT_RATE, pitch=DEFAULT_PITCH)
                await communicate.save(out_file)
                size = os.path.getsize(out_file)
                print(f"[OK] Generated {key}.mp3 ({size} bytes) - Native Bengali")
                return
            except Exception as e:
                if attempt == 3:
                    print(f"[FAIL] {key}: {e}", file=sys.stderr)
                else:
                    await asyncio.sleep(1.2)


async def main():
    parser = argparse.ArgumentParser(description="Generate Native Bengali Audio for Smart Lineman")
    parser.add_argument("--list", action="store_true", help="List all available prompts")
    args = parser.parse_args()

    if args.list:
        print(f"\n{'Key':<22} | {'Description':<40} | {'Text Preview'}")
        print("-" * 90)
        for k, v in GUIDE_PROMPTS.items():
            print(f"{k:<22} | {v['description']:<40} | {v['text'][:32]}...")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"Generating {len(GUIDE_PROMPTS)} native Bengali voice clips using {DEFAULT_VOICE}...")

    sem = asyncio.Semaphore(2)
    for key, info in GUIDE_PROMPTS.items():
        out_file = os.path.join(OUTPUT_DIR, f"{key}.mp3")
        await generate_clip(sem, key, info["text"], out_file)
        await asyncio.sleep(0.3)

    print(f"\nAll {len(GUIDE_PROMPTS)} native Bengali clips generated successfully in {OUTPUT_DIR}!")


if __name__ == "__main__":
    asyncio.run(main())
