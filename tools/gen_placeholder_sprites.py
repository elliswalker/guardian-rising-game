"""Generate placeholder pixel sprites for Guardian Rising structures & props.

Sprites that game scripts tint at runtime (walls, towers, frames, trees, ship
hull) are drawn in near-white grayscale so `modulate` multiplication produces
the intended color. Objects with no tint logic (locker, sparrow, build site,
critter) get baked colors.

Run from the Game/ directory:  python tools/gen_placeholder_sprites.py
"""

import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

# Grayscale ramp for modulate-tinted sprites
W1 = (242, 242, 245, 255)  # lightest — main fill
W2 = (210, 212, 218, 255)  # mid — shading
W3 = (168, 172, 180, 255)  # dark — seams/outline
W4 = (120, 124, 132, 255)  # darkest — deep shadow


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(im, x0, y0, x1, y1, c):
    """Inclusive-coordinate filled rectangle."""
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


# ── wall.png 5×34 — plated barricade courses ─────────────────────────────────
def gen_wall():
    im = canvas(5, 34)
    rect(im, 0, 0, 4, 33, W2)
    # horizontal course seams every 6px, offset edges
    for y in range(5, 34, 6):
        rect(im, 0, y, 4, y, W4)
    # left light edge / right shadow edge
    rect(im, 0, 0, 0, 33, W1)
    rect(im, 4, 0, 4, 33, W3)
    # top cap
    rect(im, 0, 0, 4, 1, W1)
    save(im, "structures", "wall.png")


# ── tower.png 12×48 — legged watchtower with turret head ─────────────────────
def gen_tower():
    im = canvas(12, 48)
    # legs
    rect(im, 1, 38, 3, 47, W3)
    rect(im, 8, 38, 10, 47, W3)
    # base plate
    rect(im, 0, 36, 11, 39, W2)
    rect(im, 0, 36, 11, 36, W1)
    # shaft
    rect(im, 3, 14, 8, 36, W2)
    rect(im, 3, 14, 3, 36, W1)
    rect(im, 8, 14, 8, 36, W3)
    for y in range(18, 36, 5):  # panel seams
        rect(im, 4, y, 7, y, W3)
    # turret head — wider block
    rect(im, 0, 6, 11, 14, W2)
    rect(im, 0, 6, 11, 7, W1)
    rect(im, 0, 13, 11, 14, W3)
    # barrel nub pointing right
    rect(im, 9, 9, 11, 11, W4)
    # antenna
    rect(im, 2, 2, 2, 6, W3)
    px(im, 2, 1, W1)
    save(im, "structures", "tower.png")


# ── frame.png 12×26 — boxy worker robot (near-white; job color = modulate) ──
def gen_frame():
    im = canvas(12, 26)
    # head
    rect(im, 3, 0, 8, 5, W2)
    rect(im, 3, 0, 8, 0, W1)
    rect(im, 4, 2, 7, 3, W4)  # visor
    # neck
    rect(im, 5, 6, 6, 7, W3)
    # torso
    rect(im, 2, 8, 9, 16, W2)
    rect(im, 2, 8, 2, 16, W1)
    rect(im, 9, 8, 9, 16, W3)
    rect(im, 5, 10, 6, 14, W3)  # chest seam
    # arms
    rect(im, 0, 9, 1, 15, W3)
    rect(im, 10, 9, 11, 15, W3)
    # hips
    rect(im, 3, 17, 8, 18, W3)
    # legs
    rect(im, 3, 19, 4, 25, W2)
    rect(im, 7, 19, 8, 25, W2)
    rect(im, 3, 25, 4, 25, W4)
    rect(im, 7, 25, 8, 25, W4)
    save(im, "structures", "frame.png")


# ── locker.png 14×34 — stasis cabinet (baked dark teal) ──────────────────────
def gen_locker():
    T1 = (26, 70, 92, 255)    # frame
    T2 = (15, 56, 77, 255)    # body
    T3 = (10, 38, 54, 255)    # recess
    T4 = (70, 130, 155, 255)  # highlight
    im = canvas(14, 34)
    rect(im, 0, 0, 13, 33, T1)
    rect(im, 1, 1, 12, 32, T2)
    # window slot showing dormant silhouette
    rect(im, 4, 4, 9, 18, T3)
    rect(im, 6, 6, 7, 9, (60, 74, 80, 255))    # head shadow
    rect(im, 5, 10, 8, 16, (52, 66, 72, 255))  # body shadow
    # frame highlight edge
    rect(im, 0, 0, 13, 0, T4)
    rect(im, 0, 0, 0, 33, T4)
    # vents
    for y in (24, 27, 30):
        rect(im, 4, y, 9, y, T3)
    save(im, "structures", "locker.png")


# ── build_site.png 10×4 — foundation plate (baked amber) ─────────────────────
def gen_build_site():
    A1 = (255, 191, 26, 255)
    A2 = (214, 148, 10, 255)
    A3 = (255, 226, 130, 255)
    im = canvas(10, 4)
    rect(im, 0, 1, 9, 3, A2)
    rect(im, 0, 1, 9, 1, A1)
    # corner studs
    for x in (0, 4, 9):
        px(im, x, 0, A3)
    save(im, "structures", "build_site.png")


# ── tree foliage 20×26 + trunk 7×12 (near-white; greens/browns via modulate) ─
def gen_tree():
    fol = canvas(20, 26)
    # clustered blobs
    rect(fol, 4, 0, 15, 7, W2)
    rect(fol, 1, 5, 18, 15, W2)
    rect(fol, 3, 14, 16, 21, W2)
    rect(fol, 6, 20, 13, 25, W3)
    # light top-left, shade bottom-right
    rect(fol, 4, 0, 15, 1, W1)
    rect(fol, 1, 5, 2, 12, W1)
    rect(fol, 16, 10, 18, 15, W3)
    # leaf noise
    for (x, y) in [(6, 3), (12, 5), (4, 9), (15, 8), (9, 12), (13, 16), (6, 17), (10, 22)]:
        px(fol, x, y, W1)
    save(fol, "structures", "tree_foliage.png")

    trk = canvas(7, 12)
    rect(trk, 2, 0, 4, 11, W2)
    rect(trk, 2, 0, 2, 11, W1)
    rect(trk, 4, 0, 4, 11, W3)
    # root flare
    rect(trk, 1, 10, 5, 11, W2)
    px(trk, 0, 11, W3)
    px(trk, 6, 11, W3)
    save(trk, "structures", "tree_trunk.png")


# ── sparrow.png 30×11 — hover bike (baked) ───────────────────────────────────
def gen_sparrow():
    B1 = (168, 152, 122, 255)  # tan body
    B2 = (120, 108, 86, 255)   # underside
    B3 = (216, 202, 172, 255)  # highlight
    E1 = (80, 170, 255, 255)   # engine glow
    E2 = (30, 90, 160, 255)
    im = canvas(30, 11)
    # main hull — long wedge
    rect(im, 2, 3, 27, 6, B1)
    rect(im, 2, 6, 27, 7, B2)
    rect(im, 4, 2, 22, 2, B3)
    # nose taper
    rect(im, 26, 4, 29, 5, B1)
    px(im, 29, 4, B3)
    # cockpit hump
    rect(im, 10, 0, 16, 2, B1)
    rect(im, 10, 0, 16, 0, B3)
    # rear fins
    rect(im, 0, 1, 3, 2, B2)
    rect(im, 0, 4, 1, 6, B2)
    # engine glow (rear + under-thrusters)
    rect(im, 0, 7, 2, 8, E1)
    px(im, 0, 9, E2)
    for x in (7, 14, 21):
        rect(im, x, 8, x + 1, 8, E1)
        px(im, x, 9, E2)
    save(im, "player", "sparrow.png")


# ── ship_hull.png 52×14 — jumpship silhouette (near-white; stage tint) ───────
def gen_ship_hull():
    im = canvas(52, 14)
    # central fuselage
    rect(im, 8, 4, 43, 10, W2)
    rect(im, 8, 4, 43, 4, W1)
    rect(im, 8, 10, 43, 10, W4)
    # nose taper right
    rect(im, 44, 5, 49, 9, W2)
    rect(im, 50, 6, 51, 8, W3)
    # cockpit
    rect(im, 34, 1, 41, 4, W2)
    rect(im, 35, 2, 40, 3, W4)
    # wings
    rect(im, 2, 6, 8, 8, W3)
    rect(im, 0, 5, 3, 6, W3)
    rect(im, 12, 11, 20, 12, W3)
    rect(im, 30, 11, 38, 12, W3)
    # panel seams
    for x in (16, 24, 32):
        rect(im, x, 5, x, 9, W3)
    # landing skids
    rect(im, 14, 13, 17, 13, W4)
    rect(im, 33, 13, 36, 13, W4)
    save(im, "structures", "ship_hull.png")


# ── critter.png 8×6 — field scavenger (baked brown) ──────────────────────────
def gen_critter():
    C1 = (140, 107, 71, 255)
    C2 = (110, 82, 54, 255)
    C3 = (180, 148, 108, 255)
    im = canvas(8, 6)
    rect(im, 1, 2, 6, 4, C1)   # body
    rect(im, 1, 2, 6, 2, C3)   # back highlight
    rect(im, 5, 0, 6, 2, C2)   # head/ear
    px(im, 6, 1, (20, 16, 12, 255))  # eye
    px(im, 0, 3, C2)           # tail
    px(im, 2, 5, C2)           # legs
    px(im, 5, 5, C2)
    save(im, "world", "critter.png")


if __name__ == "__main__":
    gen_wall()
    gen_tower()
    gen_frame()
    gen_locker()
    gen_build_site()
    gen_tree()
    gen_sparrow()
    gen_ship_hull()
    gen_critter()
    print("done")
