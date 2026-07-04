"""Generate ambient music loops for Guardian Rising (#39).

Kingdom's calm/tense engine is mostly sound: a warm pad owns the day, a
dark drone owns the night, and the crossfade IS the dusk announcement.
Both loops are built from integer-Hz partials over a whole-second length,
so every sine completes an exact cycle count and the loop point is
mathematically seamless. LFO rates are k/DUR for the same reason.

22050 Hz mono 16-bit, ~-12 dB peak — meant to sit far under the SFX.

Run from Game/:  python tools/gen_music_loops.py
"""

import math
import os
import struct
import wave

SR = 22050
DUR = 24  # seconds — whole number keeps every integer frequency seamless
N = SR * DUR
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

TAU = 2 * math.pi


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
    print("wrote", name, f"{len(samples)/SR:.1f}s")


def lfo(t, cycles, lo=0.0, hi=1.0, phase=0.0):
    """Sine LFO completing an exact `cycles` count over the loop."""
    return lo + (hi - lo) * 0.5 * (1.0 + math.sin(TAU * cycles * t / DUR + phase))


def normalize(out, peak_target=0.25):
    peak = max(abs(s) for s in out)
    return [s / peak * peak_target for s in out]


def gen_day():
    """Warm major-ish pad: rebuilt City serenity. A drone with a third that
    breathes in and out, and a faint shimmer far above."""
    out = []
    for i in range(N):
        t = i / SR
        s = 0.0
        # root drone — A1/A2, steady
        s += 0.50 * math.sin(TAU * 55 * t)
        s += 0.30 * math.sin(TAU * 110 * t)
        # fifth, swelling gently (2 breaths per loop)
        s += 0.22 * lfo(t, 2, 0.35, 1.0) * math.sin(TAU * 165 * t)
        # major third, offset breathing (3 per loop) — the "hope" note
        s += 0.16 * lfo(t, 3, 0.15, 0.9, math.pi) * math.sin(TAU * 275 * t)
        # airy shimmer, sparse and quiet
        s += 0.06 * lfo(t, 5, 0.0, 1.0, 1.3) * math.sin(TAU * 440 * t)
        s += 0.04 * lfo(t, 7, 0.0, 1.0, 2.6) * math.sin(TAU * 660 * t)
        # whole-pad slow breath so it never sits static
        s *= lfo(t, 1, 0.8, 1.0)
        out.append(s)
    write_wav("music_day.wav", normalize(out, 0.25))


def gen_night():
    """Dark pressure drone: minor-second beating in the lows, a slow sub
    pulse like something pacing, and a thin cold whistle drifting above."""
    out = []
    for i in range(N):
        t = i / SR
        s = 0.0
        # beating low pair — 55 vs 58 Hz rubs at 3 Hz, constant unease
        s += 0.45 * math.sin(TAU * 55 * t)
        s += 0.38 * math.sin(TAU * 58 * t)
        # dark low fifth
        s += 0.20 * lfo(t, 2, 0.5, 1.0) * math.sin(TAU * 82 * t)
        # sub pulse — 12 slow thumps per loop (one every 2s)
        pulse = max(0.0, math.sin(TAU * 12 * t / DUR)) ** 8
        s += 0.30 * pulse * math.sin(TAU * 41 * t)
        # cold whistle, rare and thin
        s += 0.05 * lfo(t, 3, 0.0, 1.0, 0.7) * math.sin(TAU * 587 * t)
        s += 0.03 * lfo(t, 4, 0.0, 1.0, 2.1) * math.sin(TAU * 622 * t)  # minor-2nd rub up top
        s *= lfo(t, 1, 0.85, 1.0, math.pi)
        out.append(s)
    write_wav("music_night.wav", normalize(out, 0.28))


if __name__ == "__main__":
    gen_day()
    gen_night()
    print("done")
