"""Generate parallax background layers for all four planets.

320x180 PNGs (render at 2x = full 640x360 view), alpha backgrounds,
silhouette-band style matching the placeholder art. All ridgelines are
built from integer-cycle sine sums so every layer TILES SEAMLESSLY for
the loader's horizontal mirroring. Structures never straddle the seam.

Layers per planet (far -> near):
  layer_0  celestial / sky detail   (slowest)
  layer_1  distant ridge / horizon
  layer_2  landmark silhouettes
  layer_3  near ground scatter      (fastest)

Run from Game/:  python tools/gen_parallax_backgrounds.py
"""

import math
import os
import random
from PIL import Image

W, H = 320, 180
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "backgrounds")
random.seed(41)


def canvas():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def px(im, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        im.putpixel((int(x), int(y)), c)


def rect(im, x0, y0, x1, y1, c):
    for y in range(max(0, int(y0)), min(H, int(y1) + 1)):
        for x in range(max(0, int(x0)), min(W, int(x1) + 1)):
            im.putpixel((x, y), c)


def save(im, planet, name):
    path = os.path.join(OUT, planet, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)
    print("wrote", planet + "/" + name)


def ridge(im, base_y, amp, cycles, color, *, rough=0.0, dither=True):
    """Fill a periodic ridgeline downward. Integer cycle counts = seamless."""
    phases = [random.uniform(0, math.tau) for _ in cycles]
    for x in range(W):
        t = x / W * math.tau
        h = base_y
        for (cyc, weight), ph in zip(cycles, phases):
            h += math.sin(t * cyc + ph) * amp * weight
        if rough:
            h += random.uniform(-rough, rough)
        h = int(h)
        for y in range(max(0, h), H):
            im.putpixel((x, y), color)
        if dither and h > 0 and random.random() < 0.45:
            px(im, x, h - 1, color)


def stars(im, count, colors):
    for _ in range(count):
        x = random.randint(0, W - 1)
        y = random.randint(0, int(H * 0.75))
        c = random.choice(colors)
        px(im, x, y, c)
        if random.random() < 0.12:  # occasional bright cross
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                px(im, x + dx, y + dy, (c[0], c[1], c[2], 120))


def cloud_band(im, y_center, count, w_range, color):
    """Elliptical cloud blobs; kept off the seam so the tile wraps clean."""
    for _ in range(count):
        cw = random.randint(*w_range)
        ch = max(2, cw // 5)
        cx = random.randint(cw // 2 + 2, W - cw // 2 - 2)
        cy = y_center + random.randint(-14, 14)
        for y in range(cy - ch, cy + ch + 1):
            for x in range(cx - cw // 2, cx + cw // 2 + 1):
                nx = (x - cx) / (cw / 2)
                ny = (y - cy) / max(1, ch)
                if nx * nx + ny * ny <= 1.0:
                    px(im, x, y, color)


def tower_block(im, x, top, w, color, *, cap=None, antenna=False):
    rect(im, x, top, x + w - 1, H - 1, color)
    if cap:
        rect(im, x - 1, top - 2, x + w, top, cap)
    if antenna:
        ax = x + w // 2
        rect(im, ax, top - 8, ax, top - 2, color)
        px(im, ax, top - 9, (255, 90, 80, 200))  # aircraft light


# ── EARTH — Last City outskirts ───────────────────────────────────────────────
def gen_earth():
    # 0: the Traveler + high clouds
    im = canvas()
    tx, ty, tr = 250, 46, 22
    for y in range(ty - tr, ty + tr + 1):
        for x in range(tx - tr, tx + tr + 1):
            d2 = (x - tx) ** 2 + (y - ty) ** 2
            if d2 <= tr * tr:
                shade_v = 235 if (x - tx) - (y - ty) < 0 else 208
                px(im, x, y, (shade_v, shade_v, min(255, shade_v + 8), 255))
    # broken shard beneath it
    rect(im, tx - 3, ty + tr + 3, tx + 2, ty + tr + 6, (215, 215, 224, 180))
    cloud_band(im, 78, 7, (24, 70), (188, 196, 210, 90))
    save(im, "earth", "layer_0.png")

    # 1: mountains + the City wall far off
    im = canvas()
    ridge(im, 108, 16, [(2, 1.0), (5, 0.5), (11, 0.25)], (96, 106, 124, 255))
    rect(im, 20, 84, 90, H - 1, (120, 128, 144, 255))   # the Wall — flat, vast
    rect(im, 20, 84, 90, 86, (140, 148, 162, 255))
    for x in range(26, 90, 9):                            # wall seams
        rect(im, x, 88, x, H - 1, (108, 116, 132, 255))
    save(im, "earth", "layer_1.png")

    # 2: ruined suburb skyline
    im = canvas()
    ridge(im, 138, 6, [(3, 1.0), (7, 0.4)], (70, 78, 94, 255))
    for x, w, top in [(12, 10, 116), (48, 7, 126), (95, 12, 108), (150, 8, 122),
                      (192, 14, 112), (243, 9, 124), (284, 11, 118)]:
        tower_block(im, x, top, w, (70, 78, 94, 255), cap=(82, 90, 106, 255),
                    antenna=(x % 3 == 0))
    save(im, "earth", "layer_2.png")

    # 3: near rubble + dead trees
    im = canvas()
    ridge(im, 162, 4, [(4, 1.0), (9, 0.5)], (52, 58, 72, 255), rough=1.0)
    for x in [30, 88, 141, 210, 268]:
        rect(im, x, 146, x + 1, 161, (46, 52, 64, 255))       # trunk
        for i, (dx, dy) in enumerate([(-4, -4), (3, -7), (-2, -10)]):
            rect(im, x + dx, 146 + dy, x + dx + 3, 147 + dy, (46, 52, 64, 255))
    save(im, "earth", "layer_3.png")


# ── COSMODROME — rusted launch yards ─────────────────────────────────────────
def gen_cosmodrome():
    im = canvas()
    cloud_band(im, 60, 8, (30, 80), (150, 148, 156, 70))
    cloud_band(im, 95, 5, (20, 50), (135, 132, 142, 55))
    save(im, "cosmodrome", "layer_0.png")

    im = canvas()
    ridge(im, 116, 12, [(3, 1.0), (6, 0.5)], (98, 92, 96, 255))
    save(im, "cosmodrome", "layer_1.png")

    # 2: gantries + a dead colony ship on the horizon
    im = canvas()
    ridge(im, 146, 5, [(2, 1.0), (5, 0.4)], (78, 72, 74, 255))
    for x in [40, 130, 235]:                                  # launch gantries
        rect(im, x, 92, x + 2, H - 1, (72, 66, 68, 255))
        rect(im, x + 8, 100, x + 10, H - 1, (72, 66, 68, 255))
        for y in range(96, 150, 7):                           # crossbeams
            rect(im, x, y, x + 10, y, (72, 66, 68, 255))
        px(im, x + 1, 90, (255, 90, 80, 200))
    hx = 175                                                  # ship hull, half-buried
    for i in range(40):
        y_top = 128 + int(12 * math.sin(i / 40 * math.pi))
        rect(im, hx + i, y_top, hx + i, H - 1, (86, 80, 82, 255))
    save(im, "cosmodrome", "layer_2.png")

    im = canvas()
    ridge(im, 164, 3, [(5, 1.0), (13, 0.4)], (58, 54, 56, 255), rough=1.0)
    for x in [22, 75, 160, 240, 295]:                          # fence posts + debris
        rect(im, x, 152, x, 163, (52, 48, 50, 255))
        px(im, x + random.randint(2, 6), 162, (52, 48, 50, 255))
    save(im, "cosmodrome", "layer_3.png")


# ── MOON — Hellmouth dark ─────────────────────────────────────────────────────
def gen_moon():
    im = canvas()
    stars(im, 120, [(220, 224, 235, 255), (170, 178, 200, 200), (140, 200, 160, 160)])
    save(im, "moon", "layer_0.png")

    im = canvas()
    ridge(im, 112, 14, [(2, 1.0), (7, 0.4)], (56, 58, 76, 255))
    save(im, "moon", "layer_1.png")

    # 2: bone spires of the Hellmouth
    im = canvas()
    ridge(im, 148, 5, [(3, 1.0), (8, 0.4)], (44, 46, 62, 255))
    for x, hgt in [(35, 60), (90, 38), (148, 72), (205, 45), (262, 58)]:
        for i in range(hgt):                                   # tapering spire
            half = max(1, (hgt - i) * 3 // hgt)
            rect(im, x - half, H - 40 - i, x + half, H - 40 - i, (44, 46, 62, 255))
        px(im, x, H - 40 - hgt - 1, (120, 235, 130, 160))      # sickly tip glow
    save(im, "moon", "layer_2.png")

    im = canvas()
    ridge(im, 164, 3, [(4, 1.0), (11, 0.5)], (34, 36, 48, 255), rough=1.0)
    for x in [48, 120, 198, 270]:                              # crater rocks
        rect(im, x, 158, x + 6, 164, (30, 32, 44, 255))
        rect(im, x + 1, 156, x + 4, 157, (30, 32, 44, 255))
    save(im, "moon", "layer_3.png")


# ── MARS — Meridian Bay war haze ─────────────────────────────────────────────
def gen_mars():
    im = canvas()
    cloud_band(im, 70, 9, (36, 90), (168, 122, 92, 60))        # dust haze bands
    cloud_band(im, 100, 6, (28, 66), (150, 104, 78, 50))
    save(im, "mars", "layer_0.png")

    im = canvas()
    ridge(im, 110, 10, [(2, 1.0), (4, 0.5)], (128, 84, 62, 255))  # mesas: flat-ish
    for x0, x1, top in [(45, 105, 96), (190, 275, 90)]:           # true flat tables
        rect(im, x0, top, x1, H - 1, (128, 84, 62, 255))
        rect(im, x0 + 4, top + 6, x1 - 4, top + 7, (114, 74, 54, 255))
    save(im, "mars", "layer_1.png")

    # 2: cabal war machines on the horizon
    im = canvas()
    ridge(im, 146, 5, [(3, 1.0), (6, 0.4)], (96, 62, 50, 255))
    for x in [60, 210]:                                        # landed warship legs
        rect(im, x, 108, x + 42, 122, (76, 50, 44, 255))       # hull slab
        rect(im, x + 4, 122, x + 8, H - 1, (76, 50, 44, 255))
        rect(im, x + 34, 122, x + 38, H - 1, (76, 50, 44, 255))
        px(im, x + 21, 106, (255, 190, 90, 200))               # amber running light
    for x in [140, 290]:                                       # extraction chimneys
        rect(im, x, 118, x + 3, H - 1, (82, 54, 46, 255))
    save(im, "mars", "layer_2.png")

    im = canvas()
    ridge(im, 163, 4, [(5, 1.0), (12, 0.4)], (70, 46, 38, 255), rough=1.2)
    for x in [35, 110, 185, 255]:                              # pod wreckage
        rect(im, x, 156, x + 5, 163, (60, 40, 34, 255))
        px(im, x + 2, 154, (60, 40, 34, 255))
    save(im, "mars", "layer_3.png")


if __name__ == "__main__":
    gen_earth()
    gen_cosmodrome()
    gen_moon()
    gen_mars()
    print("done")
