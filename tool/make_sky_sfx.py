"""Synthesises the storm cues for ladder step 26 "আকাশ পড়ুন" (sky_read.dart).

Run: python -I tool/make_sky_sfx.py
Writes mono 22.05 kHz 16-bit WAVs into assets/sounds/learn/:
  thunder_far.wav  — a distant roll: low, soft, no crack
  thunder_near.wav — a close strike: a sharp crack, then a heavy roll
  wind_gust.wav    — a gust rising and falling through the wires
Deterministic (fixed seeds).
"""

import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds", "learn")


def _t(sec):
    return np.arange(int(SR * sec)) / SR


def _lowpass(x, hi):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    spec[f > hi] = 0
    return np.fft.irfft(spec, len(x))


def _bandpass(x, lo, hi):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    spec[(f < lo) | (f > hi)] = 0
    return np.fft.irfft(spec, len(x))


def _norm(x, peak):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def _write(name, x):
    os.makedirs(OUT, exist_ok=True)
    x = np.clip(x, -1, 1)
    pcm = (x * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def _roll(sec, hi, seed, bumps):
    """Rumbling low noise with a few swells (the roll of thunder)."""
    rng = np.random.default_rng(seed)
    t = _t(sec)
    n = _lowpass(rng.standard_normal(len(t)), hi)
    env = np.zeros(len(t))
    for start, width, amp in bumps:
        env += amp * np.exp(-((t - start) / width) ** 2)
    env *= np.minimum(1, t / 0.08) * np.minimum(1, (sec - t) / 0.5)
    return n * env


def thunder_far():
    x = _roll(2.6, 180, 41, ((0.5, 0.35, 0.8), (1.1, 0.45, 1.0), (1.8, 0.5, 0.6)))
    return _norm(x, 0.7)


def thunder_near():
    t = _t(2.4)
    rng = np.random.default_rng(43)
    crack = _bandpass(rng.standard_normal(len(t)), 900, 7000) * np.exp(-t * 26)
    crack += _bandpass(rng.standard_normal(len(t)), 200, 1600) * np.exp(-t * 9) * 0.7
    roll = _roll(2.4, 260, 44, ((0.25, 0.25, 1.0), (0.8, 0.4, 0.9), (1.5, 0.5, 0.55)))
    return _norm(np.tanh((_norm(crack, 1.0) + _norm(roll, 0.9)) * 1.6), 0.9)


def wind_gust():
    t = _t(1.8)
    rng = np.random.default_rng(45)
    n = rng.standard_normal(len(t))
    body = _bandpass(n, 120, 900)
    whistle = _bandpass(n, 900, 1500) * 0.35
    env = np.sin(np.pi * t / t[-1]) ** 1.6 * (1 + 0.25 * np.sin(2 * np.pi * 1.7 * t))
    return _norm((body + whistle) * env, 0.6)


if __name__ == "__main__":
    _write("thunder_far.wav", thunder_far())
    _write("thunder_near.wav", thunder_near())
    _write("wind_gust.wav", wind_gust())
    print("wrote thunder_far.wav thunder_near.wav wind_gust.wav")
