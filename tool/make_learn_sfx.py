"""Synthesises the Learn board cues (mono 22.05 kHz 16-bit WAV).

Run: python -I tool/make_learn_sfx.py
Writes into assets/sounds/learn/. Deterministic (fixed seeds).
"""

import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds", "learn")


def _t(sec):
    return np.arange(int(SR * sec)) / SR


def _bandpass(x, lo, hi):
    """FFT band-pass; lo/hi may be arrays (time-varying via short frames)."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    mask = ((f >= lo) & (f <= hi)).astype(float)
    return np.fft.irfft(spec * mask, len(x))


def _sweep_noise(sec, f0, f1, width, seed):
    """Noise whose pass band glides f0 -> f1 (frame-wise)."""
    rng = np.random.default_rng(seed)
    n = int(SR * sec)
    out = np.zeros(n)
    frame = 256
    win = np.hanning(frame * 2)
    noise = rng.standard_normal(n + frame * 2)
    for start in range(0, n, frame):
        p = start / max(1, n - 1)
        fc = f0 + (f1 - f0) * p
        seg = noise[start:start + frame * 2] * win
        seg = _bandpass(seg, fc - width / 2, fc + width / 2)
        end = min(n, start + frame * 2)
        out[start:end] += seg[: end - start]
    return out


def _env(n, attack, release_pow=1.0):
    a = max(1, int(n * attack))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a) ** 0.6
    e[a:] = np.linspace(1, 0, n - a) ** release_pow
    return e


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


def card_deal(seed, pitch):
    """Card flicked off the deck: airy swish, then a soft felt tap."""
    swish = _sweep_noise(0.11, 2600 * pitch, 5200 * pitch, 1800, seed)
    swish *= _env(len(swish), 0.35, 1.6)
    tap_t = _t(0.05)
    tap = np.sin(2 * np.pi * 220 * pitch * tap_t) * np.exp(-tap_t * 90)
    tap += np.random.default_rng(seed + 1).standard_normal(len(tap_t)) * np.exp(-tap_t * 260) * 0.5
    out = np.zeros(int(SR * 0.17))
    out[: len(swish)] += _norm(swish, 0.55)
    s = int(SR * 0.095)
    out[s:s + len(tap)] += _norm(tap, 0.5)
    return _norm(out, 0.8)


def rush_whoosh():
    """Heavy body rushing past: low-to-mid glide with a breathy tail."""
    w = _sweep_noise(0.42, 300, 1400, 700, 7)
    w *= _env(len(w), 0.55, 2.2)
    return _norm(w, 0.85)


def stomp():
    """Boot landing: pitched-down thump + grit."""
    t = _t(0.32)
    f = 95 * np.exp(-t * 7) + 42
    phase = 2 * np.pi * np.cumsum(f) / SR
    body = np.sin(phase) * np.exp(-t * 11)
    grit = np.random.default_rng(3).standard_normal(len(t))
    grit = _bandpass(grit, 150, 2400) * np.exp(-t * 45) * 0.6
    return _norm(np.tanh((body + grit) * 2.2), 0.92)


def tag_slap():
    """Warning tag slapped on: short punch + two-tone alert blip."""
    t = _t(0.26)
    punch = np.random.default_rng(11).standard_normal(len(t))
    punch = _bandpass(punch, 400, 3500) * np.exp(-t * 70)
    blip = np.zeros(len(t))
    for i, (f, s) in enumerate(((880, 0.02), (660, 0.10))):
        st = int(SR * s)
        bt = _t(0.09)
        tone = np.sign(np.sin(2 * np.pi * f * bt)) * 0.35 + np.sin(2 * np.pi * f * bt) * 0.65
        tone *= np.exp(-bt * 28)
        blip[st:st + len(bt)] += tone[: len(blip) - st]
    return _norm(_norm(punch, 0.6) + _norm(blip, 0.45), 0.8)


def swoosh_out():
    """Rival storming off: bright glide falling away."""
    w = _sweep_noise(0.38, 1800, 400, 900, 21)
    w *= _env(len(w), 0.18, 1.4)
    return _norm(w, 0.75)


if __name__ == "__main__":
    _write("card_deal_a.wav", card_deal(1, 1.0))
    _write("card_deal_b.wav", card_deal(2, 1.12))
    _write("rush_in.wav", rush_whoosh())
    _write("stomp.wav", stomp())
    _write("tag_slap.wav", tag_slap())
    _write("rush_out.wav", swoosh_out())
    print("wrote", sorted(os.listdir(OUT)))
