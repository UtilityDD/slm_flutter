"""Kaggle notebook: generate Level 1 Bengali audio with maya2-native (Maya3TTS).

Run this in a Kaggle GPU notebook:
  - Accelerator: GPU (P100 or T4, 16 GB VRAM)
  - Internet: ON
  - Upload LADDER_VOICE_SCRIPTS.md to the notebook (it reads from cwd)

Outputs:
  assets/sounds/learn_voice/c_<sha1>.wav   (coach / Ostad, 22 kHz mono WAV)
  assets/sounds/learn_voice/r_<sha1>.wav   (rival / careless coworker, 22 kHz mono WAV)
  tool/level1_voice_manifest.json          (line_id -> asset path map)
"""

import hashlib
import json
import math
import re
import sys
from pathlib import Path

try:
    import torch
    from maya3 import Maya3TTS
except ImportError:
    print("First cell: !pip install 'maya3[server] @ git+https://github.com/MayaResearch/maya2-native' soundfile scipy")
    sys.exit(1)

import soundfile as sf
from scipy.signal import resample_poly

SRC = Path("LADDER_VOICE_SCRIPTS.md")
OUT_DIR = Path("assets/sounds/learn_voice")
MANIFEST = Path("tool/level1_voice_manifest.json")
TARGET_SR = 22050  # AGENTS.md: WAV mono 22 kHz

COACH_VOICE = "Jahnavi"   # warm adult female, Bengali coverage
RIVAL_VOICE = "Anirban"   # adult male, Bengali coverage


def _sha1(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:10]


def parse_table_rows(text: str):
    """Parse markdown table rows: | `line_id` | character | situation | **"bengali"** |"""
    entries = []
    pat = re.compile(
        r"\|\s*`([^`]+)`\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*\*\*(.+?)\*\*\s*\|"
    )
    for m in pat.finditer(text):
        line_id, character, situation, bengali = m.groups()
        bengali = bengali.strip().strip('"').strip()
        if bengali:
            entries.append({
                "line_id": line_id.strip(),
                "character": character.strip(),
                "situation": situation.strip(),
                "text": bengali,
            })
    return entries


def parse_bullet_entries(text: str):
    """Parse bullet entries: `do.1.1.kit.intro`: **"bengali"**"""
    entries = []
    seen = set()
    pat = re.compile(r"`([^`]+)`:\s*\*\*(.+?)\*\*", re.DOTALL)
    for m in pat.finditer(text):
        line_id, bengali = m.groups()
        bengali = bengali.strip().strip('"').strip()
        line_id = line_id.strip()
        if bengali and line_id not in seen:
            seen.add(line_id)
            entries.append({
                "line_id": line_id,
                "character": "",
                "situation": "",
                "text": bengali,
            })
    return entries


def is_rival(line_id: str, character: str) -> bool:
    """Rival = careless coworker. Detect via line_id or character column."""
    lid = line_id.lower()
    ch = character.lower()
    return ("rival" in lid or "coworker" in lid or "অসাবidant" in ch or "রাইভাল" in ch)


def resample_to_22k(waveform: "np.ndarray", src_sr: int = 24000) -> "np.ndarray":
    if src_sr == TARGET_SR:
        return waveform
    g = math.gcd(src_sr, TARGET_SR)
    return resample_poly(waveform.astype("float32"), TARGET_SR // g, src_sr // g).astype("float32")


def main():
    if not SRC.exists():
        print(f"ERROR: {SRC} not found. Upload LADDER_VOICE_SCRIPTS.md to this Kaggle notebook.")
        sys.exit(1)

    md_text = SRC.read_text(encoding="utf-8")
    table_entries = parse_table_rows(md_text)
    bullet_entries = parse_bullet_entries(md_text)

    # Merge, preferring table entries (they have character info)
    by_id = {e["line_id"]: e for e in table_entries}
    for e in bullet_entries:
        if e["line_id"] not in by_id:
            by_id[e["line_id"]] = e

    entries = list(by_id.values())
    print(f"Found {len(entries)} unique voice lines in {SRC}")

    print("Loading Maya3TTS from maya-research/maya2-native (max_seats=1) ...")
    tts = Maya3TTS.from_pretrained("maya-research/maya2-native", max_seats=1)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)

    manifest = {"coach": {}, "rival": {}}
    done = 0
    skipped = 0
    failed = 0

    for i, entry in enumerate(entries):
        line_id = entry["line_id"]
        text = entry["text"]
        character = entry.get("character", "")

        rival = is_rival(line_id, character)
        voice_name = RIVAL_VOICE if rival else COACH_VOICE
        group = "rival" if rival else "coach"
        prefix = "r" if rival else "c"

        filename = f"{prefix}_{_sha1(text)}.wav"
        out_path = OUT_DIR / filename

        if out_path.exists() and out_path.stat().st_size > 0:
            skipped += 1
            manifest[group][line_id] = f"sounds/learn_voice/{filename}"
            continue

        print(f"[{i+1}/{len(entries)}] {line_id} ({group}/{voice_name})")
        print(f"  {text[:70]}...")

        try:
            waveform = tts.generate(text, lang="bn", voice=voice_name, normalize=True)
            waveform_22k = resample_to_22k(waveform, 24000)
            sf.write(out_path, waveform_22k, TARGET_SR)
            done += 1
            manifest[group][line_id] = f"sounds/learn_voice/{filename}"
        except Exception as exc:
            failed += 1
            print(f"  FAIL: {exc}", file=sys.stderr)

    tts.close()

    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"\nDone: {done} generated, {skipped} cached, {failed} failed")
    print(f"Manifest: {MANIFEST}  ({len(manifest['coach'])} coach, {len(manifest['rival'])} rival)")


if __name__ == "__main__":
    main()
