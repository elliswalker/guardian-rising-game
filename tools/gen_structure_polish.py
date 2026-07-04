"""Structure polish pass (#33) — camp, job posts, vault, portal, flag, glimmer.

Same rules as gen_placeholder_sprites.py: anything a script tints at runtime
(encampment tower tiers, job banners, vault pads, portal arch/energy, attack
flag banner) is drawn in near-white grayscale so `modulate` multiplication
lands the intended color. Baked-color sprites (camp tents, glimmer crystal)
carry their own palette.

Run from the Game/ directory:  python tools/gen_structure_polish.py
"""

import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

W1 = (242, 242, 245, 255)  # lightest — main fill
W2 = (210, 212, 218, 255)  # mid — shading
W3 = (168, 172, 180, 255)  # dark — seams/outline
W4 = (120, 124, 132, 255)  # darkest — deep shadow


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < im.width and 0 <= y < im.height:
                im.putpixel((x, y), c)


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def save(im, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)
    print("wrote", os.path.relpath(path, ROOT), im.size)


# ── encampment_camp.png 92x28 — baked tent cluster around the tower ─────────
def gen_camp():
    TAN1 = (170, 146, 108, 255)   # canvas lit
    TAN2 = (132, 112, 82, 255)    # canvas shade
    TAN3 = (96, 80, 58, 255)      # canvas dark / entrance
    WOOD = (98, 74, 48, 255)
    WOOD2 = (66, 50, 32, 255)
    CRATE = (124, 98, 62, 255)
    CRATE2 = (88, 68, 42, 255)
    EMBER = (255, 150, 40, 255)
    EMBER2 = (200, 70, 20, 255)
    STONE = (110, 112, 118, 255)
    im = canvas(92, 28)
    # ground tarp
    rect(im, 2, 26, 89, 27, (70, 66, 58, 200))
    # left ridge tent (peak at x=14)
    for i in range(11):
        rect(im, 14 - i, 12 + i, 14 + i, 12 + i, TAN1 if i < 6 else TAN2)
    rect(im, 4, 22, 24, 25, TAN2)
    rect(im, 11, 18, 17, 25, TAN3)         # entrance flap
    rect(im, 14, 12, 14, 25, WOOD2)        # ridge pole seam
    px(im, 14, 11, WOOD)                   # pole tip
    # right smaller tent (peak at x=76)
    for i in range(8):
        rect(im, 76 - i, 16 + i, 76 + i, 16 + i, TAN2 if i < 5 else TAN3)
    rect(im, 69, 23, 83, 25, TAN3)
    rect(im, 74, 20, 78, 25, (60, 50, 38, 255))
    # crate stack
    rect(im, 33, 18, 41, 25, CRATE)
    rect(im, 33, 18, 41, 18, (160, 130, 88, 255))
    rect(im, 37, 18, 37, 25, CRATE2)
    rect(im, 34, 12, 40, 17, CRATE)
    rect(im, 34, 12, 40, 12, (160, 130, 88, 255))
    rect(im, 34, 15, 40, 15, CRATE2)
    # fire pit (stone ring + embers)
    rect(im, 52, 24, 60, 25, STONE)
    rect(im, 54, 22, 58, 23, EMBER2)
    px(im, 55, 21, EMBER)
    px(im, 57, 20, EMBER)
    px(im, 56, 22, (255, 220, 120, 255))
    # supply barrels
    rect(im, 46, 20, 49, 25, (72, 84, 96, 255))
    rect(im, 46, 20, 49, 20, (110, 124, 138, 255))
    rect(im, 46, 22, 49, 22, (52, 62, 72, 255))
    save(im, "structures", "encampment_camp.png")


# ── encampment_tower_t1..t4.png — watch platform that grows with tier ────────
def _tower_legs(im, y_top, y_bot, x0, x1):
    rect(im, x0, y_top, x0 + 1, y_bot, W3)
    rect(im, x1 - 1, y_top, x1, y_bot, W3)
    # cross brace
    mid = (y_top + y_bot) // 2
    rect(im, x0, mid, x1, mid, W4)


def gen_camp_towers():
    # T1 14x28 — stilt platform with lookout rail
    im = canvas(14, 28)
    _tower_legs(im, 10, 27, 2, 11)
    rect(im, 0, 8, 13, 10, W2)      # deck
    rect(im, 0, 8, 13, 8, W1)
    rect(im, 1, 3, 1, 7, W3)        # rail posts
    rect(im, 12, 3, 12, 7, W3)
    rect(im, 1, 3, 12, 3, W2)       # rail
    save(im, "structures", "encampment_tower_t1.png")

    # T2 14x40 — adds a scaffold level + tarp roof
    im = canvas(14, 40)
    _tower_legs(im, 22, 39, 2, 11)
    rect(im, 0, 20, 13, 22, W2)
    rect(im, 0, 20, 13, 20, W1)
    _tower_legs(im, 10, 19, 3, 10)
    rect(im, 1, 8, 12, 10, W2)
    rect(im, 1, 8, 12, 8, W1)
    for i in range(4):              # tarp roof slope
        rect(im, 2 + i, 4 + i, 11 - i, 4 + i, W3)
    save(im, "structures", "encampment_tower_t2.png")

    # T3 16x52 — enclosed cabin with window slit
    im = canvas(16, 52)
    _tower_legs(im, 34, 51, 2, 13)
    rect(im, 0, 32, 15, 34, W2)
    rect(im, 0, 32, 15, 32, W1)
    _tower_legs(im, 22, 31, 3, 12)
    rect(im, 1, 20, 14, 22, W2)
    rect(im, 1, 20, 14, 20, W1)
    rect(im, 2, 8, 13, 19, W2)      # cabin
    rect(im, 2, 8, 13, 8, W1)
    rect(im, 2, 8, 2, 19, W1)
    rect(im, 13, 8, 13, 19, W3)
    rect(im, 5, 12, 10, 14, W4)     # window slit
    for i in range(3):              # roof
        rect(im, 3 + i, 5 + i, 12 - i, 5 + i, W3)
    save(im, "structures", "encampment_tower_t3.png")

    # T4 16x64 — spire + banner over the cabin
    im = canvas(16, 64)
    _tower_legs(im, 46, 63, 2, 13)
    rect(im, 0, 44, 15, 46, W2)
    rect(im, 0, 44, 15, 44, W1)
    _tower_legs(im, 34, 43, 3, 12)
    rect(im, 1, 32, 14, 34, W2)
    rect(im, 1, 32, 14, 32, W1)
    rect(im, 2, 20, 13, 31, W2)     # cabin
    rect(im, 2, 20, 13, 20, W1)
    rect(im, 2, 20, 2, 31, W1)
    rect(im, 13, 20, 13, 31, W3)
    rect(im, 5, 24, 10, 26, W4)
    for i in range(3):
        rect(im, 3 + i, 17 + i, 12 - i, 17 + i, W3)
    rect(im, 7, 4, 8, 17, W3)       # spire pole
    rect(im, 9, 4, 14, 9, W1)       # banner flying right
    rect(im, 9, 9, 12, 10, W2)      # tattered lower edge
    px(im, 14, 5, W2)
    save(im, "structures", "encampment_tower_t4.png")


# ── job_banner.png 12x26 — near-white hanging banner (job color = modulate) ──
def gen_job_banner():
    im = canvas(12, 26)
    rect(im, 5, 0, 6, 25, W3)       # pole
    px(im, 5, 0, W1)
    rect(im, 0, 2, 5, 2, W3)        # crossbar
    rect(im, 0, 3, 4, 14, W1)       # banner cloth
    rect(im, 0, 3, 4, 4, W2)
    rect(im, 4, 3, 4, 14, W2)
    rect(im, 0, 15, 1, 17, W1)      # tattered tails
    rect(im, 3, 15, 4, 16, W2)
    rect(im, 1, 8, 3, 10, W4)       # emblem block
    rect(im, 4, 23, 7, 25, W4)      # base plate
    save(im, "structures", "job_banner.png")


# ── vault_pad.png 14x18 — near-white terminal pedestal (mode = modulate) ─────
def gen_vault_pad():
    im = canvas(14, 18)
    rect(im, 2, 15, 11, 17, W3)     # base
    rect(im, 4, 8, 9, 15, W2)       # column
    rect(im, 4, 8, 4, 15, W1)
    rect(im, 9, 8, 9, 15, W4)
    rect(im, 1, 2, 12, 8, W2)       # console head (angled slab)
    rect(im, 1, 2, 12, 2, W1)
    rect(im, 3, 4, 10, 6, W4)       # screen
    px(im, 4, 5, W1)                # screen glint
    save(im, "structures", "vault_pad.png")


# ── portal_arch.png 44x66 + portal_energy.png 24x54 (faction = modulate) ─────
def gen_portal():
    arch = canvas(44, 66)
    # columns — jagged alien plating
    for (x0, x1) in ((0, 9), (34, 43)):
        rect(arch, x0, 10, x1, 65, W2)
        rect(arch, x0, 10, x0, 65, W1)
        rect(arch, x1, 10, x1, 65, W4)
        for y in range(16, 64, 9):
            rect(arch, x0 + 1, y, x1 - 1, y, W3)
    # crown spanning the top
    rect(arch, 4, 4, 39, 12, W2)
    rect(arch, 4, 4, 39, 5, W1)
    rect(arch, 18, 0, 25, 6, W3)    # keystone
    rect(arch, 20, 1, 23, 3, W4)    # keystone core
    # inner lip framing the energy field
    rect(arch, 9, 12, 9, 60, W3)
    rect(arch, 34, 12, 34, 60, W3)
    # base plates
    rect(arch, 0, 62, 11, 65, W3)
    rect(arch, 32, 62, 43, 65, W3)
    save(arch, "structures", "portal_arch.png")

    en = canvas(24, 54)
    for y in range(54):
        for x in range(24):
            # vertical shimmer bands with ragged edges
            edge = 2 if (y * 7 + x * 3) % 11 < 3 else 0
            if edge <= x < 24 - edge:
                band = (x + y // 3) % 6
                c = W1 if band < 2 else (W2 if band < 4 else W3)
                px(en, x, y, c)
    # holes torn in the field
    for (hx, hy) in ((5, 9), (16, 20), (8, 33), (18, 44), (3, 48)):
        rect(en, hx, hy, hx + 2, hy + 2, (0, 0, 0, 0))
    save(en, "structures", "portal_energy.png")


# ── attack_flag_banner.png 14x14 — war banner cloth (state color = modulate) ─
def gen_flag_banner():
    im = canvas(14, 14)
    rect(im, 0, 0, 11, 9, W1)
    rect(im, 0, 0, 11, 0, W2)
    rect(im, 11, 0, 11, 9, W2)
    # swallowtail cut
    rect(im, 8, 4, 11, 5, (0, 0, 0, 0))
    rect(im, 0, 10, 3, 12, W2)      # tails
    rect(im, 6, 10, 8, 11, W2)
    rect(im, 2, 3, 5, 6, W4)        # emblem
    px(im, 3, 4, W2)
    save(im, "structures", "attack_flag_banner.png")


# ── glimmer_crystal.png 12x14 — baked programmable-matter shard cluster ──────
def gen_glimmer_crystal():
    B1 = (150, 210, 255, 255)   # facet light
    B2 = (70, 140, 235, 255)    # body
    B3 = (30, 80, 170, 255)     # dark facet
    B4 = (210, 240, 255, 255)   # glint
    im = canvas(12, 14)
    # main shard — tall diamond
    for i, (x0, x1) in enumerate(((5, 6), (4, 7), (3, 8), (3, 8), (4, 7), (5, 6))):
        rect(im, x0, 2 + i, x1, 2 + i, B2)
    rect(im, 4, 3, 5, 6, B1)        # lit facet
    rect(im, 7, 4, 8, 7, B3)        # shaded facet
    px(im, 5, 2, B4)
    # side shard left
    rect(im, 1, 8, 2, 12, B2)
    px(im, 1, 8, B1)
    px(im, 2, 12, B3)
    # side shard right
    rect(im, 9, 9, 10, 12, B2)
    px(im, 9, 9, B1)
    px(im, 10, 12, B3)
    # base scatter
    rect(im, 3, 12, 8, 13, B3)
    px(im, 4, 12, B2)
    px(im, 7, 12, B2)
    save(im, "world", "glimmer_crystal.png")


if __name__ == "__main__":
    gen_camp()
    gen_camp_towers()
    gen_job_banner()
    gen_vault_pad()
    gen_portal()
    gen_flag_banner()
    gen_glimmer_crystal()
    print("done")
