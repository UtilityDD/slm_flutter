"""ElevenLabs Bengali Voice Generator for Smart Lineman Guide.

Reads ELEVENLABS_API_KEY from .env, synthesizes high-fidelity, energetic
Bengali voice clips for the Guide Mascot, and saves them to assets/sounds/.

Usage:
  python tool/generate_elevenlabs_voice.py
  python tool/generate_elevenlabs_voice.py --list
  python tool/generate_elevenlabs_voice.py --clip gate_intro
"""

import os
import sys
import json
import argparse
import urllib.request
import urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_PATH = os.path.join(ROOT, ".env")
OUTPUT_DIR = os.path.join(ROOT, "assets", "sounds", "guide_voice")


def load_env():
    env = {}
    if os.path.exists(ENV_PATH):
        with open(ENV_PATH, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip().strip('"').strip("'")
    return env


# Curated catalog of Guide audio prompts: energetic, commanding, inspiring
GUIDE_PROMPTS = {
    # --- Batch 1: Universal Guide Presence & Inspirations ---
    "guide_welcome": {
        "text": "নমস্কার লাইনম্যান দাদা! কাজে নামার আগে প্রতিটি সুরক্ষা নিয়ম ঝালিয়ে নিন।",
        "description": "Warm, inspiring daily welcome on the ladder",
        "mood": "warm_commanding",
    },
    "guide_praise_great": {
        "text": "সাবাশ! একদম খাঁটি লাইনম্যানের মতো নিখুঁত কাজ হয়েছে!",
        "description": "High praise on flawless execution",
        "mood": "energetic_celebrate",
    },
    "guide_warn_danger": {
        "text": "সাবধান! সুরক্ষায় কোনো আপস নয়, আগে নিজের জীবন তারপর কাজ!",
        "description": "Urgent life-saving caution",
        "mood": "urgent_commanding",
    },
    "guide_halt_mistake": {
        "text": "থামুন! এক মুহূর্তের ভুলে বড় বিপদ হতে পারে। নিয়ম মেনে পুনরায় চেষ্টা করুন।",
        "description": "Firm interruption on dangerous slip",
        "mood": "firm_protective",
    },
    "guide_rank_up": {
        "text": "অভিনন্দন! আপনি নতুন পদোন্নতি এবং সুরক্ষা কবচ অর্জন করেছেন!",
        "description": "Heroic rank elevation fanfare",
        "mood": "triumphant",
    },

    # --- Universal Reusable Expressions Across All Levels ---
    "exp_right_1": {
        "text": "সাবাশ! একদম ঠিক।",
        "description": "Universal punchy praise for correct tap",
        "mood": "cheerful",
    },
    "exp_right_2": {
        "text": "বাঃ, একদম নিখুঁত নির্বাচন!",
        "description": "Universal praise for correct item",
        "mood": "cheerful",
    },
    "exp_right_3": {
        "text": "সঠিক সিদ্ধান্ত, পরের ধাপে চলুন।",
        "description": "Universal praise moving to next step",
        "mood": "motivating",
    },
    "exp_right_4": {
        "text": "চমৎকার! যথাযথ ফিটিং হয়েছে।",
        "description": "Universal praise for equipment fit",
        "mood": "cheerful",
    },
    "exp_wrong_holo_na": {
        "text": "না, হলো না!",
        "description": "Universal immediate reaction to wrong tap",
        "mood": "alert",
    },
    "exp_wrong_vul": {
        "text": "ভুল হলো! নিয়মটি আবার মনে করুন।",
        "description": "Universal correction prompt",
        "mood": "instructive",
    },
    "exp_wrong_bhabun": {
        "text": "না, হলো না—আবার একটু ভেবে দেখুন।",
        "description": "Universal gentle nudge on second attempt",
        "mood": "supportive",
    },
    "rank_3star": {
        "text": "চমৎকার শৃঙ্খলা! কোনো ত্রুটি ছাড়াই নিখুঁতভাবে কাজ সম্পন্ন হয়েছে!",
        "description": "3-star gold victory evaluation",
        "mood": "triumphant",
    },
    "rank_2star": {
        "text": "কাজ শেষ হয়েছে, তবে কাজের সময় আরও সতর্ক থাকা জরুরি।",
        "description": "2-star pass evaluation",
        "mood": "sober_constructive",
    },
    "rank_fail": {
        "text": "কাজে মারাত্মক ঝুঁকি থেকে গেছে। সুরক্ষার নিয়ম মেনে পুনরায় চেষ্টা করুন।",
        "description": "Retry evaluation on fail",
        "mood": "firm_encouraging",
    },

    # --- Batch 2: Step 30 Rank Gate ("প্রথম ডকেট" - First Real Field Dispatch) ---
    "gate_intro": {
        "text": "জরুরি ডকেট এলো! ১১ কেভি ফিডার মেরামত। ভ্যান থেকে সঠিক রড বাছাই, পারমিট মেলানো, পোলের শব্দ পরীক্ষা, ডিসচার্জ স্পার্ক এবং ঝড় থেকে নিরাপদে ফিরে ট্রেইনি পদোন্নতি অর্জন করুন!",
        "description": "High-octane mission briefing for Step 30 gate",
        "mood": "action_briefing",
    },
    "gate_ask_van": {
        "text": "ডকেট ১১ কেভি লাইনের। ভ্যান থেকে ঠিক রডটি বেছে নিন।",
        "description": "Station 1 tool selection prompt",
        "mood": "focused",
    },
    "gate_ask_ptw": {
        "text": "সাইটের ফিডার প্লেট দেখুন। ফোনে কাজ শুরু করবেন, না থামবেন?",
        "description": "Station 2 Permit to work verification",
        "mood": "serious_alert",
    },
    "gate_ask_pole": {
        "text": "পোল ঘুরে দেখুন ও হাতুড়ি ঠুকে পোলের ভাষা পড়ুন। উঠবেন?",
        "description": "Station 3 Pole sounding inspection",
        "mood": "investigative",
    },
    "gate_ask_discharge": {
        "text": "ডিসচার্জ ক্রম: আগে মাটি, পরে তিন ফেজে হুক ঠেকান।",
        "description": "Station 4 Earth spike first sequence",
        "mood": "safety_critical",
    },
    "gate_ask_storm": {
        "text": "আকাশে বজ্র ডাকছে! সহকর্মীর চাপ মানবেন না, সরাসরি ভ্যানে নিরাপদ আশ্রয়ে চলুন!",
        "description": "Station 5 Storm evacuation alert",
        "mood": "urgent_warning",
    },
    "gate_mission_done": {
        "text": "অভিনন্দন! প্রথম ডকেট সম্পূর্ণ সফল! আপনি এখন অনুমোদিত ট্রেইনি লাইনম্যান!",
        "description": "Victory announcement upon completing Rank Gate",
        "mood": "triumphant",
    },

    # --- Batch 3: Field Characters & Dispatch Radio ---
    "control_room_radio": {
        "text": "হ্যালো লাইনম্যান! রামপুর ১১ কেভি ফিডার ব্রেকার নামিয়েছি। তোমরা গাছে উঠে কাজ সেরে নাও — শাটডাউনের কাগজ পরে পাঠিয়ে দিচ্ছি!",
        "description": "Control room operator's verbal rush shortcut over radio",
        "mood": "radio_dispatcher",
    },
    "coworker_rush_line": {
        "text": "আর একটু, শেষ করে নামি! এইটুকু কাজ ফেলে কেউ নামে?",
        "description": "Careless rival coworker pressuring to rush in lightning",
        "mood": "careless_rush",
    },
}


def synthesize_clip(api_key, text, output_path, voice_id=None, model_id="eleven_multilingual_v2"):
    """Call ElevenLabs Text-to-Speech API directly via HTTPS."""
    # Default to "Adam" / "Antoni" / "George" (deep, energetic inspiring male) if none specified
    # Common male voice IDs in ElevenLabs:
    # "pNInz6obpgDQGcFmaJgB" (Adam - deep, charismatic, energetic)
    # "ErXwobaYiN019PkySvjV" (Antoni - clear, energetic, confident)
    selected_voice = voice_id or "pNInz6obpgDQGcFmaJgB"
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{selected_voice}"

    payload = {
        "text": text,
        "model_id": model_id,
        "voice_settings": {
            "stability": 0.45,         # Slightly lower stability for energetic, expressive speech
            "similarity_boost": 0.85,  # High fidelity & clarity
            "style": 0.35,             # Confident, punchy delivery
            "use_speaker_boost": True
        }
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "xi-api-key": api_key,
            "Accept": "audio/mpeg",
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as resp:
            audio_bytes = resp.read()
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(audio_bytes)
            print(f"[OK] Generated {output_path} ({len(audio_bytes)} bytes)")
            return True
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode("utf-8", errors="ignore")
        print(f"[FAIL] HTTP {e.code}: {error_msg}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"[FAIL] {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="ElevenLabs Voice Generator for Smart Lineman")
    parser.add_argument("--list", action="store_true", help="List all available prompts")
    parser.add_argument("--clip", type=str, help="Generate only a specific clip key")
    args = parser.parse_args()

    if args.list:
        print(f"\n{'Key':<22} | {'Description':<40} | {'Text Preview'}")
        print("-" * 90)
        for k, v in GUIDE_PROMPTS.items():
            print(f"{k:<22} | {v['description']:<40} | {v['text'][:32]}...")
        return

    env = load_env()
    api_key = env.get("ELEVENLABS_API_KEY", "").strip()
    voice_id = env.get("ELEVENLABS_VOICE_ID", "").strip() or None
    model_id = env.get("ELEVENLABS_MODEL_ID", "eleven_multilingual_v2").strip()

    if not api_key:
        print("[!] Error: ELEVENLABS_API_KEY is not set in .env file.")
        print("    Please edit .env in the project root and add your ElevenLabs API key:")
        print("    ELEVENLABS_API_KEY=your_key_here\n")
        sys.exit(1)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    targets = [args.clip] if args.clip else list(GUIDE_PROMPTS.keys())
    success_count = 0

    for key in targets:
        if key not in GUIDE_PROMPTS:
            print(f"[!] Unknown clip key: {key}")
            continue
        info = GUIDE_PROMPTS[key]
        out_file = os.path.join(OUTPUT_DIR, f"{key}.mp3")
        print(f"Synthesizing [{key}]...")
        if synthesize_clip(api_key, info["text"], out_file, voice_id=voice_id, model_id=model_id):
            success_count += 1

    print(f"\nDone! Synthesized {success_count}/{len(targets)} clips into {OUTPUT_DIR}")


if __name__ == "__main__":
    main()

