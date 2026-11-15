"""Synthesises the brand chime played when the Home shield is opened big.

A soft two-note bell (G5 then D6, a rising fifth) with a faint high shimmer,
1.4 s, mono 44.1 kHz. Owner choice 2026-11-15: "chime" (the intro
soundtrack's own last hit is cut off at the file end, so it cannot be reused).

Run: python -I tool/make_brand_chime.py
Writes assets/sounds/brand_chime.ogg (needs ffmpeg on PATH). Deterministic.
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds", "brand_chime.ogg")
LENGTH = 1.4


def _bell(f0, start, gain):
    t = np.arange(int(SR * LENGTH)) / SR - start
    on = t >= 0
    t = np.where(on, t, 0)
    # Bell-like partials: fundamental, octave, a soft inharmonic upper pair.
    partials = [(1.0, 1.0, 1.1), (2.0, 0.42, 0.7), (2.76, 0.18, 0.45), (5.4, 0.07, 0.25)]
    x = np.zeros_like(t)
    for ratio, amp, decay in partials:
        x += amp * np.sin(2 * np.pi * f0 * ratio * t) * np.exp(-t / decay)
    attack = np.clip(t / 0.006, 0, 1)
    return gain * x * attack * on


def main():
    n = int(SR * LENGTH)
    x = _bell(783.99, 0.0, 0.55) + _bell(1174.66, 0.12, 0.5)
    # Shimmer: a quiet, slowly beating high pair.
    t = np.arange(n) / SR
    shimmer = (np.sin(2 * np.pi * 3135.96 * t) + np.sin(2 * np.pi * 3139.5 * t)) * 0.035
    x += shimmer * np.clip((t - 0.1) / 0.15, 0, 1) * np.exp(-np.maximum(t - 0.1, 0) / 0.5)
    # Fade the last 120 ms to silence.
    fade = np.clip((LENGTH - t) / 0.12, 0, 1)
    x *= fade
    x = x / np.max(np.abs(x)) * 0.6
    pcm = (x * 32767).astype("<i2")
    with tempfile.TemporaryDirectory() as d:
        wav = os.path.join(d, "chime.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5",
                        os.path.abspath(OUT)], check=True)
    print("wrote", os.path.abspath(OUT))


if __name__ == "__main__":
    main()
