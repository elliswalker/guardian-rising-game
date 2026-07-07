"""Wide stitched parallax plates — the 'evolution of Kingdom' pass (#50).

The old 320px tiles repeat every screen and the eye catches it instantly.
This builder authors 960px (3-segment) plates for Cosmodrome, Moon and
Mars: same seamless integer-cycle ridges, but every segment carries a
DIFFERENT arrangement of Pro landmarks and scatter, so the repeat period
is three screens of varied scenery. Earth keeps its hand-made plates.

Passes per planet (far -> near):
  layer_0  sky gradient + clouds/stars across the full width
  layer_1  distant ridge with far silhouettes
  layer_2  landmark band — per-segment compositions
  layer_3  near scatter bench
  layer_4  immediate props band
  fg_0     foreground ground cover, density scaled to width

Run from Game/:  python tools/build_wide_backgrounds.py
"""

import math
import os
import random

from PIL import Image

import gen_parallax_backgrounds as gp
import build_planet_backgrounds as bp

SEGMENTS = 3
gp.W = 320 * SEGMENTS  # module global read at call time by every gp helper
W = gp.W
H = gp.H
LAND = bp.LAND
OUT = bp.OUT


def seg_x(seg, frac):
    """x position at a fraction across segment seg (0..SEGMENTS-1)."""
    return int(320 * seg + 320 * frac)


def save(im, planet, name):
    bp.finish(im, rim=1.12, shade=1.0)
    im.save(os.path.join(OUT, planet, name))
    print("wrote", planet + "/" + name, im.size)


# ── COSMODROME ────────────────────────────────────────────────────────────────
def cosmodrome():
    random.seed(710)
    # 0: sky — haze bands wander across all three segments
    im = gp.canvas()
    gp.grad_sky(im, (86, 98, 120), (172, 158, 146))
    gp.haze_blobs(im, 44, 18, (36, 88), (168, 172, 184), 120)
    gp.haze_blobs(im, 74, 24, (30, 80), (150, 148, 156), 100)
    gp.haze_blobs(im, 104, 15, (22, 55), (188, 178, 168), 80)
    save(im, "cosmodrome", "layer_0.png")

    # 1: distant hills
    im = gp.canvas()
    gp.ridge_ramped(im, 116, 12, [(5, 1.0), (11, 0.5)], (105, 100, 104, 255))
    save(im, "cosmodrome", "layer_1.png")

    # 2: landmark band — seg A: colony ship; seg B: gantry pair;
    #    seg C: half-buried ship stern + lone gantry. No two screens alike.
    im = gp.canvas()
    gp.ridge_ramped(im, 146, 5, [(4, 1.0), (9, 0.4)], (80, 74, 76, 255))
    sky = (172, 158, 146)
    ship = bp.haze(bp.load_scaled("cosmodrome_ship.png", 78), sky, 0.30)
    gantry = bp.haze(bp.load_scaled("cosmodrome_gantry.png", 90), sky, 0.38)
    gantry_s = bp.haze(bp.load_scaled("cosmodrome_gantry.png", 66), sky, 0.44)
    bp.paste_grounded(im, ship, seg_x(0, 0.35), 158)
    bp.paste_grounded(im, gantry_s, seg_x(0, 0.05), 156)
    bp.paste_grounded(im, gantry, seg_x(1, 0.18), 156)
    bp.paste_grounded(im, gantry.transpose(Image.FLIP_LEFT_RIGHT), seg_x(1, 0.62), 157)
    stern = ship.transpose(Image.FLIP_LEFT_RIGHT).crop((0, 0, ship.width // 2, ship.height))
    bp.paste_grounded(im, stern, seg_x(2, 0.55), 166)  # buried deeper
    bp.paste_grounded(im, gantry_s.transpose(Image.FLIP_LEFT_RIGHT), seg_x(2, 0.15), 156)
    save(im, "cosmodrome", "layer_2.png")

    # 3: near bench — fence posts + debris scattered the whole width
    im = gp.canvas()
    gp.ridge_ramped(im, 164, 3, [(7, 1.0), (17, 0.4)], (58, 54, 56, 255), rough=1.0)
    for _ in range(15):
        x = random.randint(6, W - 7)
        gp.rect(im, x, 152, x, 163, (48, 44, 46, 255))
        gp.px(im, x, 152, (66, 60, 62, 255))
        gp.px(im, x + random.randint(2, 6), 162, (48, 44, 46, 255))
    save(im, "cosmodrome", "layer_3.png")

    # 4: containers / spools / poles — placements rolled across 3 segments
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(8, 1.0), (19, 0.4)], (48, 45, 47, 255), rough=1.0)
    c, hl = (48, 45, 47, 255), (36, 33, 35, 255)
    for x, two_high in [(30, True), (250, False), (430, True), (585, False),
                        (660, True), (905, False)]:
        gp.rect(im, x, 160, x + 34, 171, c)
        for gx in range(x + 3, x + 34, 5):
            gp.rect(im, gx, 161, gx, 170, hl)
        if two_high:
            gp.rect(im, x + 6, 149, x + 28, 159, c)
            for gx in range(x + 9, x + 28, 5):
                gp.rect(im, gx, 150, gx, 158, hl)
    for x in [140, 350, 530, 775, 940]:
        for dy in range(-5, 6):
            half = int((25 - dy * dy) ** 0.5 * 0.55)
            gp.rect(im, x - half, 166 + dy, x + half, 166 + dy, c)
        gp.rect(im, x, 162, x, 170, hl)
    for x in [95, 205, 480, 720, 855]:
        for i in range(18):
            gp.px(im, x + i // 6, 170 - i, c)
        gp.rect(im, x - 3, 154, x + 6, 154, c)
    save(im, "cosmodrome", "layer_4.png")

    # fg: scrap + weeds, density x3
    im = gp.fg_canvas()
    c = (26, 22, 21, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(27):
        x = random.randint(4, W - 12)
        w_p = random.randint(5, 10)
        for i in range(w_p):
            gp.fg_rect(im, x + i, gp.FG_H - 4 - i // 2, x + i, gp.FG_H - 3, c)
    for _ in range(54):
        x = random.randint(2, W - 3)
        h = random.randint(3, 7)
        for i in range(h):
            gp.fg_px(im, x, gp.FG_H - 3 - i, c)
    save(im, "cosmodrome", "fg_0.png")


# ── MOON ──────────────────────────────────────────────────────────────────────
def moon():
    random.seed(711)
    # 0: void sky + galaxy dust + stars across the full width
    im = gp.canvas()
    gp.grad_sky(im, (6, 6, 14), (26, 28, 44))
    for _ in range(480):
        x = random.randint(0, W - 1)
        y = random.randint(30, 90)
        if random.random() < 0.5:
            gp.px(im, x, y, (34, 34, 52, 255))
    gp.stars(im, 450, [(220, 224, 235, 255), (170, 178, 200, 200),
                       (140, 200, 160, 160)])
    save(im, "moon", "layer_0.png")

    # 1: far crater rim
    im = gp.canvas()
    gp.ridge_ramped(im, 112, 14, [(4, 1.0), (13, 0.4)], (58, 60, 78, 255))
    save(im, "moon", "layer_1.png")

    # 2: landmark band — seg A: spire cluster; seg B: lone colossal spire
    #    over a crater bowl; seg C: leaning pair.
    im = gp.canvas()
    gp.ridge_ramped(im, 148, 5, [(5, 1.0), (14, 0.4)], (46, 48, 64, 255))
    sky = (26, 28, 44)

    def spire(hgt, flip=False):
        sp = bp.load_scaled("moon_spire.png", hgt)
        if flip:
            sp = sp.transpose(Image.FLIP_LEFT_RIGHT)
        return bp.haze(sp, sky, 0.22)

    bp.paste_grounded(im, spire(88), seg_x(0, 0.12), 160)
    bp.paste_grounded(im, spire(60, True), seg_x(0, 0.42), 158)
    bp.paste_grounded(im, spire(74), seg_x(0, 0.68), 160)
    bp.paste_grounded(im, spire(104, True), seg_x(1, 0.40), 162)
    bp.paste_grounded(im, spire(52), seg_x(2, 0.20), 158)
    bp.paste_grounded(im, spire(80, True), seg_x(2, 0.55), 160)
    save(im, "moon", "layer_2.png")

    # 3: near regolith bench + rocks the whole width
    im = gp.canvas()
    gp.ridge_ramped(im, 164, 3, [(7, 1.0), (16, 0.5)], (36, 38, 50, 255), rough=1.0)
    for _ in range(12):
        x = random.randint(4, W - 10)
        gp.rect(im, x, 158, x + 6, 164, (30, 32, 44, 255))
        gp.rect(im, x + 1, 156, x + 4, 157, (30, 32, 44, 255))
        gp.px(im, x + 1, 156, (44, 46, 60, 255))
    save(im, "moon", "layer_3.png")

    # 4: rib arcs + slabs, rolled across segments
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(7, 1.0), (15, 0.5)], (26, 28, 38, 255), rough=1.0)
    c = (26, 28, 38, 255)
    for x, hgt, bend in [(45, 42, 9), (190, 30, 7), (330, 48, 11), (455, 36, 8),
                         (600, 44, 10), (700, 28, 6), (860, 50, 12)]:
        for i in range(hgt):
            xo = int(bend * (i / hgt) ** 2)
            gp.rect(im, x + xo, 171 - i, x + xo + 2, 171 - i, c)
        gp.px(im, x + bend, 171 - hgt - 1, (110, 220, 125, 120))
    for x, w_s, top in [(140, 9, 148), (390, 6, 154), (540, 8, 150), (935, 7, 152)]:
        gp.rect(im, x, top, x + w_s, 171, c)
        gp.rect(im, x + 2, top - 3, x + w_s - 2, top, c)
    save(im, "moon", "layer_4.png")

    # fg: rocks + bone shards
    im = gp.fg_canvas()
    c = (14, 15, 23, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(42):
        x = random.randint(3, W - 9)
        w_r = random.randint(3, 7)
        h_r = max(2, w_r - 2)
        gp.fg_rect(im, x, gp.FG_H - 3 - h_r, x + w_r, gp.FG_H - 3, c)
        gp.fg_px(im, x + 1, gp.FG_H - 4 - h_r, c)
    for _ in range(24):
        x = random.randint(2, W - 4)
        h = random.randint(5, 10)
        for i in range(h):
            gp.fg_px(im, x + i // 4, gp.FG_H - 3 - i, c)
    save(im, "moon", "fg_0.png")


# ── MARS ──────────────────────────────────────────────────────────────────────
def mars():
    random.seed(712)
    # 0: dust sky, haze the full width
    im = gp.canvas()
    gp.grad_sky(im, (126, 76, 56), (206, 150, 110))
    gp.haze_blobs(im, 52, 21, (36, 90), (176, 128, 96), 110)
    gp.haze_blobs(im, 82, 27, (30, 80), (160, 112, 84), 95)
    gp.haze_blobs(im, 110, 18, (24, 60), (214, 164, 124), 80)
    save(im, "mars", "layer_0.png")

    # 1: mesa band — Pro mesas at different heights per segment
    im = gp.canvas()
    gp.ridge_ramped(im, 110, 10, [(4, 1.0), (7, 0.5)], (132, 88, 64, 255))
    sky1 = (206, 150, 110)
    mesa = bp.haze(bp.load_scaled("mars_mesa.png", 72), sky1, 0.42)
    mesa_s = bp.haze(bp.load_scaled("mars_mesa.png", 54), sky1, 0.48)
    bp.paste_grounded(im, mesa, seg_x(0, 0.15), 128)
    bp.paste_grounded(im, mesa_s.transpose(Image.FLIP_LEFT_RIGHT), seg_x(0, 0.70), 124)
    bp.paste_grounded(im, mesa.transpose(Image.FLIP_LEFT_RIGHT), seg_x(1, 0.45), 126)
    bp.paste_grounded(im, mesa_s, seg_x(2, 0.10), 122)
    bp.paste_grounded(im, mesa, seg_x(2, 0.60), 128)
    save(im, "mars", "layer_1.png")

    # 2: landmark band — seg A: landed warship; seg B: chimneys + wreck
    #    field; seg C: warship pair far apart.
    im = gp.canvas()
    gp.ridge_ramped(im, 146, 5, [(5, 1.0), (11, 0.4)], (98, 64, 52, 255))
    sky2 = (196, 140, 104)
    warship = bp.haze(bp.load_scaled("mars_warship.png", 64), sky2, 0.26)
    warship_s = bp.haze(bp.load_scaled("mars_warship.png", 46), sky2, 0.34)
    bp.paste_grounded(im, warship, seg_x(0, 0.30), 156)
    for x in [seg_x(1, 0.15), seg_x(1, 0.55), seg_x(1, 0.85)]:
        gp.rect(im, x, 118, x + 3, H - 1, (82, 54, 46, 255))
        gp.px(im, x + 1, 116, (150, 110, 90, 160))
        gp.px(im, x + 2, 113, (150, 110, 90, 110))
    bp.paste_grounded(im, warship_s, seg_x(2, 0.12), 154)
    bp.paste_grounded(im, warship.transpose(Image.FLIP_LEFT_RIGHT), seg_x(2, 0.62), 158)
    save(im, "mars", "layer_2.png")

    # 3: near dune bench + pod wreckage across the width
    im = gp.canvas()
    gp.ridge_ramped(im, 163, 4, [(8, 1.0), (19, 0.4)], (74, 48, 40, 255), rough=1.2)
    for _ in range(12):
        x = random.randint(4, W - 10)
        gp.rect(im, x, 156, x + 5, 163, (60, 40, 34, 255))
        gp.px(im, x + 2, 154, (60, 40, 34, 255))
        gp.px(im, x, 156, (78, 52, 44, 255))
    save(im, "mars", "layer_3.png")

    # 4: sandbags / pod / antenna, varied per segment
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(8, 1.0), (18, 0.4)], (52, 34, 28, 255), rough=1.2)
    c, hl = (52, 34, 28, 255), (40, 26, 22, 255)
    for x in [40, 265, 420, 610, 780, 915]:
        for row, (n, y) in enumerate([(5, 168), (4, 164), (3, 160)]):
            for i in range(n):
                gp.rect(im, x + row * 2 + i * 7, y, x + row * 2 + i * 7 + 5, y + 3, c)
                gp.px(im, x + row * 2 + i * 7 + 2, y + 1, hl)
    for px_x in [210, 520, 850]:
        gp.rect(im, px_x, 158, px_x + 16, 171, c)
        for i in range(10):
            gp.rect(im, px_x + 16 + i, 158 + i, px_x + 17 + i, 171, c)
        gp.rect(im, px_x + 4, 150, px_x + 6, 158, c)
        gp.px(im, px_x + 5, 148, (255, 160, 60, 140))
    for ax in [105, 465, 700]:
        gp.rect(im, ax, 146, ax + 1, 171, c)
        for dy in (150, 156, 162):
            gp.rect(im, ax - 4, dy, ax + 5, dy, hl)
    save(im, "mars", "layer_4.png")

    # fg: dust drifts + rebar
    im = gp.fg_canvas()
    c = (30, 18, 15, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(30):
        x = random.randint(4, W - 20)
        w_d = random.randint(9, 18)
        for i in range(w_d):
            h = int((1 - abs(i - w_d / 2) / (w_d / 2)) * random.randint(3, 5))
            gp.fg_rect(im, x + i, gp.FG_H - 3 - h, x + i, gp.FG_H - 3, c)
    for _ in range(21):
        x = random.randint(2, W - 4)
        h = random.randint(4, 8)
        for i in range(h):
            gp.fg_px(im, x + (i // 3), gp.FG_H - 3 - i, c)
    save(im, "mars", "fg_0.png")


if __name__ == "__main__":
    cosmodrome()
    moon()
    mars()
    print("done")
