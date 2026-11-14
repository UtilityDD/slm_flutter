"""
SLM Voice System: Edge Neural Synthesizer & Batch Generator.
"""

import asyncio
import os
import sys
from typing import Dict, List, Optional
import edge_tts

from tool.voice_system.catalog import VoiceCue
from tool.voice_system.speakers import SPEAKERS, SpeakerProfile


async def synthesize_cue(
    cue: VoiceCue,
    sem: asyncio.Semaphore,
    force: bool = False,
    retries: int = 3,
) -> bool:
    """Synthesizes a single voice cue using Edge Neural TTS."""
    if not force and os.path.exists(cue.output_path) and os.path.getsize(cue.output_path) > 1000:
        return False  # Skipped (already exists)

    speaker = SPEAKERS.get(cue.speaker_id, SPEAKERS["subrata"])
    os.makedirs(os.path.dirname(cue.output_path), exist_ok=True)

    text_to_speak = cue.normalized_text

    async with sem:
        for attempt in range(1, retries + 1):
            try:
                communicator = edge_tts.Communicate(
                    text=text_to_speak,
                    voice=speaker.voice,
                    rate=speaker.rate,
                    pitch=speaker.pitch,
                )
                await communicator.save(cue.output_path)
                return True  # Generated successfully
            except Exception as e:
                if attempt == retries:
                    print(f"\n[ERROR] Failed to synthesize {cue.key} ({cue.output_path}): {e}", file=sys.stderr)
                    return False
                await asyncio.sleep(1.0 * attempt)
    return False


async def batch_synthesize(
    cues: List[VoiceCue],
    concurrency: int = 4,
    force: bool = False,
    progress_callback=None,
) -> Dict[str, int]:
    """Batch synthesizes a list of VoiceCues concurrently."""
    sem = asyncio.Semaphore(concurrency)
    stats = {"total": len(cues), "generated": 0, "skipped": 0, "failed": 0}

    async def _worker(cue: VoiceCue):
        success = await synthesize_cue(cue, sem, force=force)
        if success:
            stats["generated"] += 1
        elif not force and os.path.exists(cue.output_path) and os.path.getsize(cue.output_path) > 1000:
            stats["skipped"] += 1
        else:
            stats["failed"] += 1

        if progress_callback:
            progress_callback(stats, cue)

    tasks = [_worker(c) for c in cues]
    await asyncio.gather(*tasks)
    return stats

