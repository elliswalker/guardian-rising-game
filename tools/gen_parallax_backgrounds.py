"""Generate parallax background layers for all four planets.

320x180 PNGs (render at 2x = full 640x360 view), alpha backgrounds,
silhouette-band style matching the placeholder art. All ridgelines are
built from integer-cycle sine sums so every layer TILES SEAMLESSLY for
the loader's horizontal mirroring. Structures never straddle the seam.

Layers per planet (far -> near):
  layer_0  celestial / sky detail   (slowest)
  layer_1  distant ridge / horizon
  layer_2  landmark silhouettes
  layer_3  near ground scatter
  layer_4  immediate background     (cars/containers/bones/barricades)
  fg_0     FOREGROUND ground cover  (320x32 strip, rendered in FRONT of
           the world by ParallaxLoader at motion_scale > 1)

Run from Game/:  python tools/gen_parallax_backgrounds.py
"""

import math
import os
import random
from PIL import Image
from sprite_style import finish

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
    # gentle K2C lit-ridge rim: crest lines catch the sky (no ground shade —
    # layer bottoms run off-frame)
    finish(im, rim=1.12, shade=1.0)
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


# ── layer_4: immediate background props (nearest silhouette band) ────────────
FG_H = 32  # foreground strip height


def fg_canvas():
    return Image.new("RGBA", (W, FG_H), (0, 0, 0, 0))


def fg_px(im, x, y, c):
    if 0 <= x < W and 0 <= y < FG_H:
        im.putpixel((int(x), int(y)), c)


def fg_rect(im, x0, y0, x1, y1, c):
    for y in range(max(0, int(y0)), min(FG_H, int(y1) + 1)):
        for x in range(max(0, int(x0)), min(W, int(x1) + 1)):
            im.putpixel((x, y), c)


def dead_tree(im, x, base_y, hgt, c):
    rect(im, x, base_y - hgt, x + 1, base_y, c)
    for i, (dx, dy, ln) in enumerate([(-1, -hgt + 4, 5), (2, -hgt + 8, 6), (-1, -hgt + 13, 4)]):
        step = -1 if dx < 0 else 1
        for j in range(ln):
            px(im, x + dx + j * step, base_y + dy - j // 2, c)


def car_husk(im, x, ground, c, hl):
    """Rusted car silhouette ~26x10, roof caved."""
    rect(im, x, ground - 6, x + 25, ground, c)          # body
    rect(im, x + 5, ground - 10, x + 19, ground - 6, c)  # cabin
    rect(im, x + 7, ground - 9, x + 11, ground - 7, hl)  # window hole
    rect(im, x + 14, ground - 9, x + 17, ground - 7, hl)
    px(im, x + 2, ground + 1, c)                         # sagged tires
    px(im, x + 22, ground + 1, c)


def gen_layer4():
    # EARTH — dead trees, car husks, guardrail, puddle glints
    im = canvas()
    ridge(im, 172, 3, [(4, 1.0), (10, 0.4)], (42, 47, 60, 255), rough=1.0)
    C, HL = (42, 47, 60, 255), (30, 34, 44, 255)
    for x in [24, 168, 262]:
        car_husk(im, x, 170, C, HL)
    for x in [72, 130, 218, 300]:
        dead_tree(im, x, 171, random.randint(22, 34), C)
    for x0 in [95, 235]:                                   # guardrail run
        rect(im, x0, 165, x0 + 30, 166, C)
        for gx in range(x0, x0 + 30, 6):
            rect(im, gx, 166, gx, 170, C)
    for x0, w in [(52, 14), (200, 10), (285, 8)]:          # puddle glints
        rect(im, x0, 175, x0 + w, 175, (96, 112, 138, 160))
    save(im, "earth", "layer_4.png")

    # COSMODROME — container stacks, cable spools, sagging power poles
    im = canvas()
    ridge(im, 172, 3, [(5, 1.0), (11, 0.4)], (48, 45, 47, 255), rough=1.0)
    C, HL = (48, 45, 47, 255), (36, 33, 35, 255)
    for x, two_high in [(30, True), (140, False), (238, True)]:
        rect(im, x, 160, x + 34, 171, C)                   # container
        for gx in range(x + 3, x + 34, 5):
            rect(im, gx, 161, gx, 170, HL)                 # corrugation
        if two_high:
            rect(im, x + 6, 149, x + 40 - 6, 159, C)
            for gx in range(x + 9, x + 34, 5):
                rect(im, gx, 150, gx, 158, HL)
    for x in [100, 210, 305]:                              # cable spools
        for dy in range(-5, 6):
            half = int((25 - dy * dy) ** 0.5 * 0.55)
            rect(im, x - half, 166 + dy, x + half, 166 + dy, C)
        rect(im, x, 162, x, 170, HL)
    for x in [75, 190]:                                    # leaning poles
        for i in range(18):
            px(im, x + i // 6, 170 - i, C)
        rect(im, x - 3, 154, x + 6, 154, C)
    save(im, "cosmodrome", "layer_4.png")

    # MOON — colossal rib arcs and monolith slabs
    im = canvas()
    ridge(im, 172, 3, [(4, 1.0), (9, 0.5)], (26, 28, 38, 255), rough=1.0)
    C = (26, 28, 38, 255)
    for x, hgt, bend in [(45, 42, 9), (110, 30, 7), (200, 48, 11), (280, 36, 8)]:
        for i in range(hgt):                               # curving rib
            xo = int(bend * (i / hgt) ** 2)
            rect(im, x + xo, 171 - i, x + xo + 2, 171 - i, C)
        px(im, x + bend, 171 - hgt - 1, (110, 220, 125, 120))
    for x, w, top in [(150, 9, 148), (250, 6, 154)]:       # slabs
        rect(im, x, top, x + w, 171, C)
        rect(im, x + 2, top - 3, x + w - 2, top, C)
    save(im, "moon", "layer_4.png")

    # MARS — sandbag barricades, crashed pod, comm antenna
    im = canvas()
    ridge(im, 172, 3, [(5, 1.0), (12, 0.4)], (52, 34, 28, 255), rough=1.2)
    C, HL = (52, 34, 28, 255), (40, 26, 22, 255)
    for x in [40, 150, 260]:                               # sandbag stacks
        for row, (n, y) in enumerate([(5, 168), (4, 164), (3, 160)]):
            for i in range(n):
                rect(im, x + row * 2 + i * 7, y, x + row * 2 + i * 7 + 5, y + 3, C)
                px(im, x + row * 2 + i * 7 + 2, y + 1, HL)
    px_x = 210                                             # crashed pod, fin up
    rect(im, px_x, 158, px_x + 16, 171, C)
    for i in range(10):
        rect(im, px_x + 16 + i, 158 + i, px_x + 17 + i, 171, C)
    rect(im, px_x + 4, 150, px_x + 6, 158, C)              # fin
    px(im, px_x + 5, 148, (255, 160, 60, 140))             # beacon
    ax = 105                                               # comm antenna
    rect(im, ax, 146, ax + 1, 171, C)
    for dy in (150, 156, 162):
        rect(im, ax - 4, dy, ax + 5, dy, HL)
    save(im, "mars", "layer_4.png")


# ── fg_0: foreground ground-cover strips (drawn IN FRONT of the world) ───────
def gen_foregrounds():
    # EARTH — grass tufts + rubble, deep blue-black
    im = fg_canvas()
    C = (20, 24, 33, 235)
    fg_rect(im, 0, FG_H - 3, W - 1, FG_H - 1, C)
    for x in range(0, W, 7):                                # ragged soil lip
        if random.random() < 0.6:
            fg_px(im, x + random.randint(0, 4), FG_H - 4, C)
    for _ in range(26):                                     # grass tufts
        x = random.randint(2, W - 3)
        h = random.randint(4, 9)
        for i in range(h):
            fg_px(im, x + (1 if i > h - 3 else 0), FG_H - 3 - i, C)
        fg_px(im, x - 1, FG_H - 4, C)
    for _ in range(7):                                      # rubble chunks
        x = random.randint(4, W - 8)
        fg_rect(im, x, FG_H - 7, x + random.randint(3, 6), FG_H - 3, C)
    save(im, "earth", "fg_0.png")

    # COSMODROME — scrap plates + weeds, rusted near-black
    im = fg_canvas()
    C = (26, 22, 21, 235)
    fg_rect(im, 0, FG_H - 3, W - 1, FG_H - 1, C)
    for _ in range(9):                                      # leaning scrap plates
        x = random.randint(4, W - 12)
        w_p = random.randint(5, 10)
        for i in range(w_p):
            fg_rect(im, x + i, FG_H - 4 - i // 2, x + i, FG_H - 3, C)
    for _ in range(18):                                     # weeds
        x = random.randint(2, W - 3)
        h = random.randint(3, 7)
        for i in range(h):
            fg_px(im, x, FG_H - 3 - i, C)
    save(im, "cosmodrome", "fg_0.png")

    # MOON — regolith rocks + bone shards, void blue
    im = fg_canvas()
    C = (14, 15, 23, 235)
    fg_rect(im, 0, FG_H - 3, W - 1, FG_H - 1, C)
    for _ in range(14):                                     # rocks
        x = random.randint(3, W - 9)
        w_r = random.randint(3, 7)
        h_r = max(2, w_r - 2)
        fg_rect(im, x, FG_H - 3 - h_r, x + w_r, FG_H - 3, C)
        fg_px(im, x + 1, FG_H - 4 - h_r, C)
    for _ in range(8):                                      # bone shards jutting
        x = random.randint(2, W - 4)
        h = random.randint(5, 10)
        for i in range(h):
            fg_px(im, x + i // 4, FG_H - 3 - i, C)
    save(im, "moon", "fg_0.png")

    # MARS — dust drifts + rebar, deep rust
    im = fg_canvas()
    C = (30, 18, 15, 235)
    fg_rect(im, 0, FG_H - 3, W - 1, FG_H - 1, C)
    for _ in range(10):                                     # dust drift mounds
        x = random.randint(4, W - 20)
        w_d = random.randint(9, 18)
        for i in range(w_d):
            h = int((1 - abs(i - w_d / 2) / (w_d / 2)) * random.randint(3, 5))
            fg_rect(im, x + i, FG_H - 3 - h, x + i, FG_H - 3, C)
    for _ in range(7):                                      # bent rebar
        x = random.randint(2, W - 4)
        h = random.randint(4, 8)
        for i in range(h):
            fg_px(im, x + (i // 3), FG_H - 3 - i, C)
    save(im, "mars", "fg_0.png")


if __name__ == "__main__":
    gen_earth()
    gen_cosmodrome()
    gen_moon()
    gen_mars()
    gen_layer4()
    gen_foregrounds()
    print("done")
