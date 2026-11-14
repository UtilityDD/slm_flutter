"""
SLM Voice System CLI (স্মার্ট লাইনম্যান ভয়েস সিস্টেম)

Unified command-line interface for the entire SLM voice infrastructure:
- Character profiles (Subrata, Careless Coworker, Radio)
- Edge Neural audio generation with phonetic acronym correction
- Dart codegen sync for Flutter game levels

Usage:
  python tool/slm_voice.py status
  python tool/slm_voice.py test
  python tool/slm_voice.py generate --target guide [--force]
  python tool/slm_voice.py generate --target all [--force]
  python tool/slm_voice.py update-dart
  python tool/slm_voice.py audit
"""

import argparse
import asyncio
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT_DIR)

from tool.voice_system.catalog import (
    get_all_cues,
    load_duty_slip_cues,
    load_guide_cues,
    load_learn_voice_cues,
)
from tool.voice_system.dart_codegen import (
    generate_duty_slip_voice,
    generate_learn_voice_map,
)
from tool.voice_system.speakers import SPEAKERS
from tool.voice_system.synthesizer import batch_synthesize


def cmd_status(args):
    """Prints current voice asset counts, file existence, and storage statistics."""
    print("==================================================================")
    print("           SLM VOICE SYSTEM: MASTER STATUS & AUDIT                ")
    print("==================================================================")

    guide_cues = load_guide_cues()
    duty_cues = load_duty_slip_cues()
    learn_cues = load_learn_voice_cues()

    categories = [
        ("Guide & Mascot (Subrata)", guide_cues, "assets/sounds/guide_voice"),
        ("Duty Slip Levels 1-14", duty_cues, "assets/sounds/voice"),
        ("Learn Boards (Coach & Rival)", learn_cues, "assets/sounds/learn_voice"),
    ]

    total_all = 0
    total_on_disk = 0
    total_bytes = 0

    print(f"{'Category':<32} {'Catalog':<10} {'On Disk':<10} {'Missing':<10} {'Size':<10}")
    print("-" * 74)

    for name, cues, folder in categories:
        cat_total = len(cues)
        on_disk = 0
        cat_bytes = 0

        for cue in cues.values():
            if os.path.exists(cue.output_path):
                on_disk += 1
                cat_bytes += os.path.getsize(cue.output_path)

        missing = cat_total - on_disk
        size_mb = f"{cat_bytes / (1024 * 1024):.2f} MB"
        print(f"{name:<32} {cat_total:<10} {on_disk:<10} {missing:<10} {size_mb:<10}")

        total_all += cat_total
        total_on_disk += on_disk
        total_bytes += cat_bytes

    print("-" * 74)
    total_missing = total_all - total_on_disk
    total_size_mb = f"{total_bytes / (1024 * 1024):.2f} MB"
    print(f"{'TOTAL ALL PROMPTS':<32} {total_all:<10} {total_on_disk:<10} {total_missing:<10} {total_size_mb:<10}")
    print("==================================================================")
    print("\nSpeakers:")
    for spk_id, spk in SPEAKERS.items():
        print(f" • {spk.name_bn:<24} | Voice: {spk.voice} | Rate: {spk.rate} | Pitch: {spk.pitch}")


def cmd_test(args):
    """Generates quick side-by-side sample audio for all speakers."""
    print("Generating side-by-side test audio in temp_test_audio/...")
    os.makedirs(os.path.join(ROOT_DIR, "temp_test_audio"), exist_ok=True)

    from tool.voice_system.catalog import VoiceCue
    from tool.voice_system.normalizer import normalize_speech_text

    samples = [
        VoiceCue(
            key="test_subrata_welcome",
            speaker_id="subrata",
            original_text="হ্যালো! আমি সুব্রত, আপনার সেফটি গাইড। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!",
            normalized_text="হ্যালো! আমি সুব্রত, আপনার সেফটি গাইড। চলুন, প্রথম ধাপ থেকে কাজ শুরু করি!",
            category="test",
            output_path=os.path.join(ROOT_DIR, "temp_test_audio", "test_subrata_welcome.mp3"),
        ),
        VoiceCue(
            key="test_subrata_ptw",
            speaker_id="subrata",
            original_text="নমস্কার! সাইটে নেমে আগে PTW ও পারমিট মিলিয়ে নিন।",
            normalized_text=normalize_speech_text("নমস্কার! সাইটে নেমে আগে PTW ও পারমিট মিলিয়ে নিন।"),
            category="test",
            output_path=os.path.join(ROOT_DIR, "temp_test_audio", "test_subrata_ptw.mp3"),
        ),
        VoiceCue(
            key="test_coworker_rush",
            speaker_id="coworker",
            original_text="আরে ধুর! আর একটু, শেষ করে নামি! এইটুকু কাজের জন্য কেউ PTW দেখতে যায়?",
            normalized_text=normalize_speech_text("আরে ধুর! আর একটু, শেষ করে নামি! এইটুকু কাজের জন্য কেউ PTW দেখতে যায়?"),
            category="test",
            output_path=os.path.join(ROOT_DIR, "temp_test_audio", "test_coworker_rush.mp3"),
        ),
    ]

    async def _run():
        stats = await batch_synthesize(samples, force=True)
        print(f"Test generation finished: {stats['generated']} generated, {stats['failed']} failed.")
        for s in samples:
            print(f" • {s.key}: {s.output_path} ({os.path.getsize(s.output_path)} bytes)")

    asyncio.run(_run())


def cmd_generate(args):
    """Batch synthesizes selected target audio cues."""
    target = args.target.lower()
    force = args.force

    if target == "guide":
        cues_map = load_guide_cues()
    elif target in ("duty-slip", "duty_slip", "levels"):
        cues_map = load_duty_slip_cues()
    elif target == "learn":
        cues_map = load_learn_voice_cues()
    elif target == "all":
        cues_map = get_all_cues()
    else:
        print(f"Unknown target: {target}. Choose from: guide, duty-slip, learn, all.")
        return

    cues_list = list(cues_map.values())
    print(f"Starting batch synthesis for '{target}' ({len(cues_list)} cues)...")
    print(f"Options: force={force}, concurrency={args.concurrency}")

    def _progress(stats, cue):
        done = stats["generated"] + stats["skipped"] + stats["failed"]
        pct = (done / stats["total"]) * 100
        print(f"\r[{done}/{stats['total']} - {pct:5.1f}%] {cue.key:<24} (gen: {stats['generated']}, skip: {stats['skipped']}, fail: {stats['failed']})", end="")

    async def _run():
        stats = await batch_synthesize(cues_list, concurrency=args.concurrency, force=force, progress_callback=_progress)
        print(f"\n\nBatch synthesis complete!")
        print(f"Total: {stats['total']} | Generated: {stats['generated']} | Skipped: {stats['skipped']} | Failed: {stats['failed']}")

    asyncio.run(_run())

    if args.sync_dart:
        cmd_update_dart(args)


def cmd_update_dart(args):
    """Updates Flutter Dart voice mapping files."""
    print("Updating Flutter Dart voice maps...")
    p1 = generate_duty_slip_voice()
    p2 = generate_learn_voice_map()
    print(f" • Updated: {p1}")
    print(f" • Updated: {p2}")
    print("Dart code generation completed.")


def cmd_audit(args):
    """Verifies that all asset references in code resolve to existing files on disk."""
    print("Running project asset reference audit (tool/check_asset_refs.py)...")
    check_script = os.path.join(ROOT_DIR, "tool", "check_asset_refs.py")
    ret = os.system(f'python "{check_script}" .')
    if ret == 0:
        print("Asset audit PASSED: 100% of referenced files exist on disk.")
    else:
        print("Asset audit FAILED: Some referenced files are missing.")


def main():
    parser = argparse.ArgumentParser(description="SLM Voice System CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # status
    subparsers.add_parser("status", help="Show catalog and on-disk voice file status")

    # test
    subparsers.add_parser("test", help="Generate side-by-side character test audio")

    # generate
    gen_p = subparsers.add_parser("generate", help="Batch synthesize voice audio")
    gen_p.add_argument("--target", default="guide", choices=["guide", "duty-slip", "learn", "all"], help="Audio category to generate")
    gen_p.add_argument("--force", action="store_true", help="Overwrite existing audio files")
    gen_p.add_argument("--concurrency", type=int, default=4, help="Concurrent synthesis requests")
    gen_p.add_argument("--sync-dart", action="store_true", help="Sync Dart maps after generation")

    # update-dart
    subparsers.add_parser("update-dart", help="Sync Flutter Dart voice mapping files")

    # audit
    subparsers.add_parser("audit", help="Verify all referenced audio assets exist")

    args = parser.parse_args()
    if args.command == "status":
        cmd_status(args)
    elif args.command == "test":
        cmd_test(args)
    elif args.command == "generate":
        cmd_generate(args)
    elif args.command == "update-dart":
        cmd_update_dart(args)
    elif args.command == "audit":
        cmd_audit(args)


if __name__ == "__main__":
    main()

