"""Composite PixelLab landmarks into Moon / Mars / Cosmodrome / Earth parallax
layers (multi-planet pass). Celestials -> layer_0, hero structures -> the
distant layer_1 (layer_2 already carries the old-pipeline structures),
foreground props -> fg_0 as near-black silhouettes (matches the car/rubble
convention).

Run from Game/:  python tools/build_pixellab_layers.py [--write] [planet ...]
Without --write, only writes tools/_preview_<planet>.png for review.
"""
import os, sys
from PIL import Image

GAME = os.path.join(os.path.dirname(__file__), "..")
BG = os.path.join(GAME, "assets", "backgrounds")
LAND = os.path.join(BG, "_landmarks")
DARK = (16, 19, 26)  # foreground silhouette colour (blue-cold near-black)

# planet -> {sky, celestial[], structures[], foreground[]}
#   celestial:  (file, x, y, height, haze)         -> layer_0
#   structures: (file, layer, x, height, haze)     -> bottom-anchored
#   foreground: (file, x, height)                  -> fg_0 silhouette
CFG = {
    "moon": {
        "sky": (5, 5, 11),
        "celestial": [("moon_earth.png", 110, 12, 88, 0.06)],
        "structures": [("moon_hive_spire.png", "layer_1", 430, 122, 0.18)],
        "foreground": [("moon_bones_a.png", 170, 22), ("moon_bones_b.png", 650, 20)],
    },
    "mars": {
        "sky": (150, 89, 52),
        "celestial": [("mars_sun.png", 690, 16, 66, 0.10)],
        "structures": [("mars_fortress.png", "layer_1", 360, 126, 0.22)],
        "foreground": [("mars_debris_a.png", 150, 24), ("mars_debris_b.png", 560, 22)],
    },
    "cosmodrome": {
        "sky": (114, 126, 143),
        "celestial": [("cosmo_traveler.png", 60, 4, 80, 0.22)],
        "structures": [("cosmo_ship_a.png", "layer_1", 520, 112, 0.18)],
        "foreground": [("cosmo_containers_a.png", 210, 26), ("cosmo_containers_b.png", 660, 24)],
    },
    # Earth already has Traveler (layer_0) + rubble (fg_0) baked in — only ADD.
    "earth": {
        "sky": (59, 75, 111),
        "celestial": [("earth_skiff.png", 700, 28, 40, 0.32)],  # distant flying skiff
        "structures": [],
        "foreground": [("earth_tree_a.png", 360, 30), ("earth_sandbags_a.png", 470, 20),
                       ("earth_barrier_a.png", 650, 18), ("earth_lamp_a.png", 880, 30)],
    },
}


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


def build(planet, write):
    d = os.path.join(BG, planet)
    cfg = CFG[planet]; sky = cfg["sky"]
    layers = {n: load(os.path.join(d, n + ".png"))
              for n in ["layer_0", "layer_1", "layer_2", "layer_3", "layer_4", "fg_0"]}
    W, H = layers["layer_0"].size
    touched = set()

    for f, x, y, h, hz in cfg["celestial"]:
        layers["layer_0"].alpha_composite(haze(scaled(load(os.path.join(LAND, f)), h), sky, hz), (x, y))
        touched.add("layer_0")
    for f, lyr, x, h, hz in cfg["structures"]:
        s = haze(scaled(load(os.path.join(LAND, f)), h), sky, hz)
        layers[lyr].alpha_composite(s, (x, H - s.height))
        touched.add(lyr)
    fg = layers["fg_0"]
    for f, x, h in cfg["foreground"]:
        s = haze(scaled(load(os.path.join(LAND, f)), h), DARK, 0.82)
        fg.alpha_composite(s, (x, fg.height - 2 - h))
    if cfg["foreground"]:
        touched.add("fg_0")

    # flattened preview far -> near
    prev = Image.new("RGBA", (W, H), sky + (255,))
    for n in ["layer_0", "layer_1", "layer_2", "layer_3", "layer_4"]:
        prev.alpha_composite(layers[n])
    prev.alpha_composite(fg, (0, H - fg.height))
    prev.convert("RGB").save(os.path.join(GAME, "tools", f"_preview_{planet}.png"))
    print(f"{planet}: touched {sorted(touched)} -> tools/_preview_{planet}.png")

    if write:
        for n in touched:
            layers[n].save(os.path.join(d, n + ".png"))
        print(f"  wrote {planet}/{sorted(touched)}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--write"]
    planets = args or list(CFG)
    for p in planets:
        build(p, "--write" in sys.argv)
