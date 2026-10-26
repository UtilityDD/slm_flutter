import math
import os
import struct
import wave

RATE = 44100


def env(i, attack, decay):
    t = i / RATE
    rise = 1 if attack <= 0 else min(1.0, t / attack)
    return rise * math.exp(-t / decay)


def voice(freq, seconds, harmonics, attack, decay):
    count = int(RATE * seconds)
    samples = []
    for i in range(count):
        t = i / RATE
        level = env(i, attack, decay)
        sample = 0.0
        for multiple, gain in harmonics:
            sample += math.sin(2 * math.pi * freq * multiple * t) * gain
        samples.append(sample * level)
    return samples


def click(seconds=0.012, gain=0.18):
    count = int(RATE * seconds)
    samples = []
    seed = 17
    for i in range(count):
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        noise = ((seed / 0x7FFFFFFF) * 2 - 1) * gain
        samples.append(noise * math.exp(-i / 28))
    return samples


def mix(parts):
    total = 1
    for start, samples in parts:
        total = max(total, int(start * RATE) + len(samples))
    buffer = [0.0] * total
    for start, samples in parts:
        offset = int(start * RATE)
        for index, sample in enumerate(samples):
            buffer[offset + index] += sample
    peak = max(abs(sample) for sample in buffer) or 1
    gain = 0.78 / peak
    return [max(-1.0, min(1.0, sample * gain)) for sample in buffer]


def write(path, samples):
    with wave.open(path, "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(b"".join(struct.pack("<h", int(sample * 32767)) for sample in samples))


bell = [(1, 1.0), (2, 0.28), (3, 0.12), (4.2, 0.05), (5.4, 0.03)]
wood = [(1, 1.0), (2, 0.18), (2.76, 0.08)]

right = mix([
    (0.0, click()),
    (0.0, voice(523.25, 0.55, bell, 0.006, 0.18)),
    (0.11, voice(659.25, 0.52, bell, 0.005, 0.17)),
    (0.22, voice(783.99, 0.62, bell, 0.004, 0.22)),
])
wrong = mix([
    (0.0, click(0.018, 0.1)),
    (0.0, voice(349.23, 0.34, wood, 0.004, 0.11)),
    (0.13, voice(261.63, 0.5, wood, 0.006, 0.16)),
])

folder = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
os.makedirs(folder, exist_ok=True)
write(os.path.join(folder, "quiz_right.wav"), right)
write(os.path.join(folder, "quiz_wrong.wav"), wrong)
print("wrote", len(right), len(wrong))
