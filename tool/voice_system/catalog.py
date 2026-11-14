"""
SLM Voice System: Master Voice Catalog Loader & Registry.

Consolidates all voice prompts across:
1. Guide & Mascot Prompts (Subrata, Radio, Coworker) -> assets/sounds/guide_voice/
2. Duty Slip Level Prompts (Level 1-14, Traps, Expressions) -> assets/sounds/voice/
3. Learn & Do Interactive Boards (Coach, Rival) -> assets/sounds/learn_voice/
"""

import hashlib
import json
import os
import sys
from dataclasses import dataclass
from typing import Dict, List, Optional

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

@dataclass
class VoiceCue:
    key: str
    speaker_id: str
    original_text: str
    normalized_text: str
    category: str
    output_path: str
    description: str = ""
    status: str = "ready"


def load_guide_cues() -> Dict[str, VoiceCue]:
    """Loads all Mascot & Universal Guide Prompts."""
    from tool.voice_system.normalizer import normalize_speech_text

    # Base Guide Prompts with Subrata as identity and updated natural phrasing
    cues_data = {
        "guide_welcome": {
            "speaker": "subrata",
            "text": "নমস্কার! আমি সুব্রত, আপনার সেফটি গাইড। কাজে নামার আগে প্রতিটি সুরক্ষা নিয়ম ঝালিয়ে নিন।",
            "description": "Daily welcome on the ladder introducing Subrata",
        },
        "guide_praise_great": {
            "speaker": "subrata",
            "text": "সাবাশ! একদম খাঁটি লাইনম্যানের মতো নিখুঁত কাজ হয়েছে!",
            "description": "High praise on flawless execution",
        },
        "guide_warn_danger": {
            "speaker": "subrata",
            "text": "সাবধান! সুরক্ষায় কোনো আপস নয়, আগে নিজের জীবন তারপর কাজ!",
            "description": "Urgent life-saving caution",
        },
        "guide_halt_mistake": {
            "speaker": "subrata",
            "text": "থামুন! এক মুহূর্তের ভুলে বড় বিপদ হতে পারে। নিয়ম মেনে পুনরায় চেষ্টা করুন।",
            "description": "Firm interruption on dangerous slip",
        },
        "guide_rank_up": {
            "speaker": "subrata",
            "text": "অভিনন্দন! আপনি নতুন পদোন্নতি এবং সুরক্ষা কবচ অর্জন করেছেন!",
            "description": "Heroic rank elevation fanfare",
        },
        "exp_right_1": {
            "speaker": "subrata",
            "text": "সাবাশ! একদম ঠিক।",
            "description": "Universal punchy praise for correct tap",
        },
        "exp_right_2": {
            "speaker": "subrata",
            "text": "বাঃ, একদম নিখুঁত নির্বাচন!",
            "description": "Universal praise for correct item",
        },
        "exp_right_3": {
            "speaker": "subrata",
            "text": "সঠিক সিদ্ধান্ত, পরের ধাপে চলুন।",
            "description": "Universal praise moving to next step",
        },
        "exp_right_4": {
            "speaker": "subrata",
            "text": "চমৎকার! যথাযথ ফিটিং হয়েছে।",
            "description": "Universal praise for equipment fit",
        },
        "exp_wrong_holo_na": {
            "speaker": "subrata",
            "text": "না, হলো না!",
            "description": "Universal immediate reaction to wrong tap",
        },
        "exp_wrong_vul": {
            "speaker": "subrata",
            "text": "ভুল হলো! নিয়মটি আবার মনে করুন।",
            "description": "Universal correction prompt",
        },
        "exp_wrong_bhabun": {
            "speaker": "subrata",
            "text": "না, হলো না—আবার একটু ভেবে দেখুন।",
            "description": "Universal gentle nudge on second attempt",
        },
        "rank_3star": {
            "speaker": "subrata",
            "text": "চমৎকার শৃঙ্খলা! কোনো ত্রুটি ছাড়াই নিখুঁতভাবে কাজ সম্পন্ন হয়েছে!",
            "description": "3-star gold victory evaluation",
        },
        "rank_2star": {
            "speaker": "subrata",
            "text": "কাজ শেষ হয়েছে, তবে কাজের সময় আরও সতর্ক থাকা জরুরি।",
            "description": "2-star pass evaluation",
        },
        "rank_fail": {
            "speaker": "subrata",
            "text": "কাজে মারাত্মক ঝুঁকি থেকে গেছে। সুরক্ষার নিয়ম মেনে পুনরায় চেষ্টা করুন।",
            "description": "Retry evaluation on fail",
        },
        "gate_intro": {
            "speaker": "subrata",
            "text": "জরুরি ডকেট এলো! ১১ কেভি ফিডার মেরামত। ভ্যান থেকে সঠিক রড বাছাই, পারমিট মেলানো, পোলের শব্দ পরীক্ষা, ডিসচার্জ স্পার্ক এবং ঝড় থেকে নিরাপদে ফিরে ট্রেইনি পদোন্নতি অর্জন করুন!",
            "description": "High-octane mission briefing for Step 30 gate",
        },
        "gate_ask_van": {
            "speaker": "subrata",
            "text": "ডকেট ১১ কেভি লাইনের। ভ্যান থেকে ঠিক রডটি বেছে নিন।",
            "description": "Station 1 tool selection prompt",
        },
        "gate_ask_ptw": {
            "speaker": "subrata",
            "text": "সাইটের ফিডার প্লেট দেখুন। ফোনে কাজ শুরু করবেন, না থামবেন?",
            "description": "Station 2 Permit to work verification",
        },
        "gate_ask_pole": {
            "speaker": "subrata",
            "text": "পোল ঘুরে দেখুন ও হাতুড়ি ঠুকে পোলের ভাষা পড়ুন। উঠবেন?",
            "description": "Station 3 Pole sounding inspection",
        },
        "gate_ask_discharge": {
            "speaker": "subrata",
            "text": "ডিসচার্জ ক্রম: আগে মাটি, পরে তিন ফেজে হুক ঠেকান।",
            "description": "Station 4 Earth spike first sequence",
        },
        "gate_ask_storm": {
            "speaker": "subrata",
            "text": "আকাশে বজ্র ডাকছে! সহকর্মীর চাপ মানবেন না, সরাসরি ভ্যানে নিরাপদ আশ্রয়ে চলুন!",
            "description": "Station 5 Storm evacuation alert",
        },
        "gate_mission_done": {
            "speaker": "subrata",
            "text": "দারুণ শৃঙ্খলা! জরুরি ডকেটের প্রতিটি বিপদ জয় করে আজ আপনি সফল ট্রেইনি লাইনম্যান!",
            "description": "Step 30 completion ceremony fanfare",
        },
        "control_room_radio": {
            "speaker": "radio",
            "text": "জরুরি বার্তা! রামপুর ১১ কেভি ফিডার ব্রেকার নামিয়েছি। তোমরা গাছে উঠে কাজ সেরে নাও — শাটডাউনের কাগজ পরে পাঠিয়ে দিচ্ছি!",
            "description": "Control room operator's verbal rush shortcut over radio",
        },
        "coworker_rush_line": {
            "speaker": "coworker",
            "text": "আর একটু, শেষ করে নামি! এইটুকু কাজ ফেলে কেউ নামে?",
            "description": "Careless rival coworker pressuring to rush in lightning",
        },
    }

    out = {}
    for key, data in cues_data.items():
        text = data["text"]
        norm = normalize_speech_text(text)
        rel_path = f"assets/sounds/guide_voice/{key}.mp3"
        out[key] = VoiceCue(
            key=key,
            speaker_id=data["speaker"],
            original_text=text,
            normalized_text=norm,
            category="guide_voice",
            output_path=os.path.join(ROOT_DIR, rel_path),
            description=data.get("description", ""),
        )
    return out


def load_duty_slip_cues() -> Dict[str, VoiceCue]:
    """Loads all 102 Duty Slip Level cues from slm_game_voice_library."""
    from tool.voice_system.normalizer import normalize_speech_text

    try:
        from tool.slm_game_voice_library import GAME_VOICE_REGISTRY
    except ImportError:
        # Fallback path if run from subdirectory
        sys.path.insert(0, os.path.join(ROOT_DIR, "tool"))
        from slm_game_voice_library import GAME_VOICE_REGISTRY

    out = {}
    for sec_id, sec_data in GAME_VOICE_REGISTRY.items():
        title = sec_data.get("title", sec_id)
        for cue_id, cue_data in sec_data.get("cues", {}).items():
            text = cue_data.get("text", "")
            norm = normalize_speech_text(text)
            rel_path = f"assets/sounds/voice/{cue_id}.mp3"
            out[cue_id] = VoiceCue(
                key=cue_id,
                speaker_id="subrata",
                original_text=text,
                normalized_text=norm,
                category=f"duty_slip_{sec_id}",
                output_path=os.path.join(ROOT_DIR, rel_path),
                description=f"{title} - {cue_data.get('tag', '')}",
            )
    return out


def load_learn_voice_cues() -> Dict[str, VoiceCue]:
    """Loads all Coach & Rival cues from learn_voice_lines.json."""
    from tool.voice_system.normalizer import normalize_speech_text

    json_path = os.path.join(ROOT_DIR, "tool", "learn_voice_lines.json")
    if not os.path.exists(json_path):
        return {}

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    out = {}
    # Coach cues
    for item in data.get("coach", []):
        t_clean = (item["say"] if isinstance(item, dict) else str(item)).strip()
        h = hashlib.sha1(t_clean.encode("utf-8")).hexdigest()[:10]
        key = f"c_{h}"
        norm = normalize_speech_text(t_clean)
        rel_path = f"assets/sounds/learn_voice/{key}.mp3"
        out[key] = VoiceCue(
            key=key,
            speaker_id="subrata",
            original_text=t_clean,
            normalized_text=norm,
            category="learn_coach",
            output_path=os.path.join(ROOT_DIR, rel_path),
            description="Learn interactive board coach guidance",
        )

    # Rival cues
    for item in data.get("rival", []):
        t_clean = (item["say"] if isinstance(item, dict) else str(item)).strip()
        h = hashlib.sha1(t_clean.encode("utf-8")).hexdigest()[:10]
        key = f"r_{h}"
        norm = normalize_speech_text(t_clean)
        rel_path = f"assets/sounds/learn_voice/{key}.mp3"
        out[key] = VoiceCue(
            key=key,
            speaker_id="coworker",
            original_text=t_clean,
            normalized_text=norm,
            category="learn_rival",
            output_path=os.path.join(ROOT_DIR, rel_path),
            description="Learn interactive board careless coworker challenge",
        )

    return out


def get_all_cues() -> Dict[str, VoiceCue]:
    """Returns combined registry of all voice cues across SLM."""
    all_cues = {}
    all_cues.update(load_guide_cues())
    all_cues.update(load_duty_slip_cues())
    all_cues.update(load_learn_voice_cues())
    return all_cues
