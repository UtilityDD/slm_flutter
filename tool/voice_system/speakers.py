"""
Speaker Profiles & Configuration for Smart Lineman (SLM) Voice System.
"""

from dataclasses import dataclass
from typing import Dict


@dataclass(frozen=True)
class SpeakerProfile:
    id: str
    name_bn: str
    name_en: str
    voice: str
    rate: str
    pitch: str
    role_desc: str


# The official SLM character speaker registry
SPEAKERS: Dict[str, SpeakerProfile] = {
    "subrata": SpeakerProfile(
        id="subrata",
        name_bn="সুব্রত (সেফটি গাইড)",
        name_en="Subrata (Safety Guide & Coach)",
        voice="bn-IN-BashkarNeural",
        rate="+14%",
        pitch="+0Hz",
        role_desc="Warm, encouraging, highly skilled West Bengal senior mentor. Speaks crisp, natural Bengali with field cadence.",
    ),
    "coworker": SpeakerProfile(
        id="coworker",
        name_bn="অসাবধান সহকর্মী",
        name_en="Careless Coworker (Rival)",
        voice="bn-BD-PradeepNeural",
        rate="-6%",
        pitch="-14Hz",
        role_desc="Gruff, hurried, impatient, shortcuts-seeking coworker. Deep and dismissive tone.",
    ),
    "radio": SpeakerProfile(
        id="radio",
        name_bn="কন্ট্রোল রুম রেডিও",
        name_en="Control Room Radio Dispatcher",
        voice="bn-IN-BashkarNeural",
        rate="+6%",
        pitch="+0Hz",
        role_desc="Fast, clipped, operational substation radio voice over the walkie-talkie.",
    ),
}

