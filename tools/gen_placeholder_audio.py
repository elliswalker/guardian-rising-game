"""Generate placeholder diegetic audio for Guardian Rising (EP-04).

Pure-python synthesis (wave module, 22050 Hz mono 16-bit). Placeholder
quality on purpose — distinct, quiet, functional. Rerun anytime.

Run from Game/:  python tools/gen_placeholder_audio.py
"""

import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(7)


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples
        )
        w.writeframes(frames)
    print("wrote", name, f"{len(samples)/SR:.2f}s")


def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)


def env_decay(i, n, power=3.0):
    return (1.0 - i / n) ** power


def ping(freq, dur, vol=0.5, power=4.0):
    n = int(SR * dur)
    return [vol * env_decay(i, n, power) * sine(freq, i / SR) for i in range(n)]


def silence(dur):
    return [0.0] * int(SR * dur)


def mix(*layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, s in enumerate(l):
            out[i] += s
    peak = max(1.0, max(abs(s) for s in out))
    return [s / peak * 0.85 for s in out]


def noise_burst(dur, vol=0.4, power=5.0, lowpass=0.3):
    n = int(SR * dur)
    out, prev = [], 0.0
    for i in range(n):
        raw = random.uniform(-1, 1)
        prev = prev + lowpass * (raw - prev)  # crude lowpass
        out.append(vol * env_decay(i, n, power) * prev)
    return out


# glimmer clink — two quick bright pings
write_wav("glimmer_clink.wav", mix(
    ping(1900, 0.10, 0.5), silence(0.03) + ping(2500, 0.09, 0.4)))

# armor scatter — descending ping spray + rattle
write_wav("glimmer_scatter.wav", mix(
    ping(2200, 0.10, 0.45),
    silence(0.04) + ping(1700, 0.10, 0.4),
    silence(0.08) + ping(1300, 0.12, 0.35),
    silence(0.11) + ping(1000, 0.14, 0.3),
    noise_burst(0.22, 0.15, 4.0, 0.5)))

# build thunk — low body + wooden tap
write_wav("build_thunk.wav", mix(
    ping(95, 0.22, 0.8, 2.5), ping(240, 0.08, 0.3), noise_burst(0.06, 0.25, 6.0, 0.2)))

# dusk stinger — slow dark swell, falling minor second
def swell(freq, dur, vol):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = math.sin(math.pi * i / n) ** 1.5  # swell in and out
        f = freq * (1.0 - 0.06 * (i / n))     # slight downward drift
        out.append(vol * e * (sine(f, t) + 0.5 * sine(f * 2.01, t)))
    return out

write_wav("dusk_stinger.wav", mix(swell(110, 1.6, 0.5), swell(82.5, 1.6, 0.4)))

# dawn chime — soft rising major arpeggio: you survived
write_wav("dawn_chime.wav", mix(
    ping(523, 0.5, 0.30, 2.0),
    silence(0.18) + ping(659, 0.5, 0.30, 2.0),
    silence(0.36) + ping(784, 0.55, 0.30, 2.0),
    silence(0.54) + ping(1046, 0.8, 0.35, 2.0)))

# wave cue — two ominous low pulses
write_wav("wave_cue.wav", mix(
    ping(65, 0.35, 0.8, 2.0), silence(0.45) + ping(65, 0.42, 0.9, 2.0),
    ping(130, 0.3, 0.2, 2.0)))

# fallen chitter — AM-modulated scratchy chirps (proximity warning)
def chitter():
    n = int(SR * 0.45)
    out, prev = [], 0.0
    for i in range(n):
        t = i / SR
        gate = 1.0 if math.sin(2 * math.pi * 14 * t) > 0.2 else 0.0
        raw = random.uniform(-1, 1)
        prev = prev + 0.6 * (raw - prev)
        tone = 0.4 * sine(900 + 300 * math.sin(2 * math.pi * 3 * t), t)
        out.append(0.4 * env_decay(i, n, 1.5) * gate * (prev * 0.5 + tone))
    return out

write_wav("fallen_chitter.wav", chitter())

# golden gun shot — sharp crack + solar tail
write_wav("golden_shot.wav", mix(
    noise_burst(0.06, 0.9, 3.0, 0.9), ping(220, 0.18, 0.5, 2.5), ping(440, 0.1, 0.3)))

# upgrade ding — bright confirmation
write_wav("upgrade_ding.wav", mix(ping(1320, 0.25, 0.4, 2.0), ping(1980, 0.3, 0.3, 2.0)))

# sparrow hum — seamless loop: exact integer periods of 55/110/165 Hz in 1.0s
def hum(dur=1.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        s = 0.5 * sine(55, t) + 0.3 * sine(110, t) + 0.12 * sine(165, t)
        out.append(0.35 * s)
    return out

write_wav("sparrow_hum.wav", hum())

print("done")
