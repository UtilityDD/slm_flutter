"""
Generate 1st Instance Mistake Audio Cues
Edge Neural: bn-IN-BashkarNeural
"""

import os
import sys
import asyncio
import edge_tts

sys.stdout.reconfigure(encoding='utf-8')

VOICE = "bn-IN-BashkarNeural"
RATE = "-1%"
PITCH = "+0Hz"
OUTPUT_DIR = os.path.abspath("assets/sounds/voice")
os.makedirs(OUTPUT_DIR, exist_ok=True)

WRONG_CUES = {
    "ds_wrong_holo_na": "না, হলো না!",
    "ds_wrong_vul_holo": "ভুল হলো!",
    "ds_wrong_bhabun": "না, হলো না—আবার ভেবে দেখুন।",
    "ds_wrong_niyom": "ভুল হলো! নিয়মটি আবার মনে করুন।",
}

async def generate():
    for cue_id, text in WRONG_CUES.items():
        out_path = os.path.join(OUTPUT_DIR, f"{cue_id}.mp3")
        communicate = edge_tts.Communicate(text, VOICE, rate=RATE, pitch=PITCH)
        await communicate.save(out_path)
        size = os.path.getsize(out_path) // 1024
        print(f"Generated {cue_id}.mp3 ({size} KB): \"{text}\"")

if __name__ == "__main__":
    asyncio.run(generate())
