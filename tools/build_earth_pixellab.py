"""Composite the PixelLab Earth landmarks into the parallax layers (#UI/maps).

Bakes the Traveler into the sky (layer_0), the Last City wall into the distant
silhouette band (layer_1), and rubble silhouettes into the foreground strip
(fg_0) — matching the haze-to-distance convention in build_planet_backgrounds.

Run from Game/:  python tools/build_earth_pixellab.py
Writes *.new.png previews first when PREVIEW_ONLY, else replaces the layers.
"""
import os, sys
from PIL import Image

GAME = os.path.join(os.path.dirname(__file__), "..")
BG = os.path.join(GAME, "assets", "backgrounds", "earth")
LAND = os.path.join(GAME, "assets", "backgrounds", "_landmarks")
PREVIEW_ONLY = "--write" not in sys.argv


def load(p):
    return Image.open(p).convert("RGBA")


def scaled(im, h):
    s = h / im.height
    return im.resize((max(1, round(im.width * s)), h), Image.NEAREST)


def haze(im, color, strength):
    out = im.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (round(r+(color[0]-r)*strength), round(g+(color[1]-g)*strength),
                        round(b+(color[2]-b)*strength), a)
    return out


def sky_color(layer0):
    # average the top band = atmospheric haze target
    top = layer0.crop((0, 0, layer0.width, 12)).convert("RGB")
    px = list(top.getdata())
    n = len(px)
    return tuple(sum(c[i] for c in px)//n for i in range(3))


def main():
    l0 = load(os.path.join(BG, "layer_0.png"))
    l1 = load(os.path.join(BG, "layer_1.png"))
    fg = load(os.path.join(BG, "fg_0.png"))
    W, H = l0.size
    sky = sky_color(l0)
    print("sky haze target:", sky)

    # --- Traveler REPLACES the crude procedural moon (blob at x220-279,y22-98).
    # Placed to cover it so there is exactly one celestial body. ---
    trav = haze(scaled(load(os.path.join(LAND, "earth_traveler.png")), 92), sky, 0.15)
    l0.alpha_composite(trav, (206, 12))
    print("traveler over old moon at", (206, 12), "size", trav.size)

    # --- Rubble silhouettes into fg_0 (near-black, like the car wrecks). ---
    dark = (16, 19, 26)
    for name, x, h in [("earth_rubble_a.png", 120, 24), ("earth_rubble_b.png", 520, 22),
                       ("earth_rubble_a.png", 800, 20)]:
        r = haze(scaled(load(os.path.join(LAND, name)), h), dark, 0.82)
        fg.alpha_composite(r, (x, fg.height - 2 - h))
    print("rubble placed x=", (120, 520, 800))

    # --- flattened preview: stack far->near over the sky base color ---
    prev = Image.new("RGBA", (W, H), sky + (255,))
    for lyr in (l0, l1, load(os.path.join(BG, "layer_2.png")),
                load(os.path.join(BG, "layer_3.png")), load(os.path.join(BG, "layer_4.png"))):
        prev.alpha_composite(lyr)
    prev.alpha_composite(fg, (0, H - fg.height))
    prev.convert("RGB").save(os.path.join(GAME, "tools", "_earth_preview.png"))
    print("wrote tools/_earth_preview.png")

    if PREVIEW_ONLY:
        print("PREVIEW ONLY — layers not modified (pass --write to commit)")
        return
    l0.save(os.path.join(BG, "layer_0.png"))
    fg.save(os.path.join(BG, "fg_0.png"))
    print("wrote earth/layer_0, fg_0")


if __name__ == "__main__":
    main()
