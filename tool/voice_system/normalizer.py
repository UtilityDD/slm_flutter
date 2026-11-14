"""
SLM Voice Normalizer & Phonetic Acronym Transcriber.

Translates technical English abbreviations, electrical field units,
and tricky Bengali conjunct phrases into natural phonetic Bengali
so that Microsoft Edge Neural TTS pronounces them flawlessly.
"""

import re
from typing import List, Tuple

# Comprehensive Acronym & Unit Replacement Map for Bengali Lineman Context
ACRONYM_MAP: List[Tuple[str, str]] = [
    # Multi-letter English technical acronyms
    (r"\bPTW\b", "পি টি ডাবলু"),
    (r"\bptw\b", "পি টি ডাবলু"),
    (r"\bDO\b", "ডি-ও"),
    (r"\bGO\b", "জি-ও"),
    (r"\bPPE\b", "পিপিই"),
    (r"\bppe\b", "পিপিই"),
    (r"\bLA\b", "এল-এ"),
    (r"\bCO2\b", "সি-ও-টু"),
    (r"\bCPR\b", "সি-পি-আর"),
    (r"\bLT\b", "এল-টি"),
    (r"\bHT\b", "এইচ-টি"),
    (r"\bMCB\b", "এম-সি-বি"),
    (r"\bMCCB\b", "এম-সি-সি-বি"),
    (r"\bGI\b", "জি-আই"),
    (r"\bPM\b", "পি-এম"),
    (r"\bFR\b", "এফ-আর"),
    (r"\bEH\b", "ই-এইচ"),
    (r"\bPCC\b", "পি-সি-সি"),
    (r"\bDTR\b", "ডি-টি-আর"),
    (r"\bSLD\b", "এস-এল-ডি"),
    (r"\bAB\b", "এ-বি"),
    (r"\bDMM\b", "ডি-এম-এম"),
    (r"\bCT\b", "সি-টি"),
    (r"\bPT\b", "পি-টি"),
    (r"\bKV\b", "কেভি"),
    (r"\bkV\b", "কেভি"),
    (r"\bkv\b", "কেভি"),
    (r"\bAMP\b", "অ্যাম্প"),
    (r"\bamp\b", "অ্যাম্প"),
    (r"\bA\b(?=\s*(?:ফেজ|লাইন|কারেন্ট))", "এ"),

    # Bengali-written acronyms that TTS mispronounces or needs hyphens
    (r"পি\.টি\.ডাবলু", "পি টি ডাবলু"),
    (r"পিটিডাবলু", "পি টি ডাবলু"),
    (r"ডি ও(?=\s)", "ডি-ও"),
    (r"জি ও(?=\s)", "জি-ও"),
]


def normalize_speech_text(text: str) -> str:
    """Normalizes text for natural Edge Neural Bengali TTS pronunciation."""
    if not text:
        return ""

    out = text

    # Apply acronym replacements
    for pattern, replacement in ACRONYM_MAP:
        out = re.sub(pattern, replacement, out)

    # Clean double spaces and normalize punctuation
    out = re.sub(r"\s+", " ", out).strip()

    # Ensure Bengali sentence terminators (। or ! or ?) are clean
    out = out.replace("।", "। ")
    out = re.sub(r"\s+", " ", out).strip()

    return out

