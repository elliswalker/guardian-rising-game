"""Build the Earth parallax stack from the real background plates (#42).

Sources: assets/backgrounds/opening_*.png — finished pixel-art plates
(the snowed-in car graveyard on the road to the Wall). This script turns
them into loader-ready layers:

- uniform 0.5x NEAREST downscale (keeps the composed scene's internal
  proportions; every remaining pixel renders 1:1 with sprite density)
- top HAZE FADE on each near layer so layers blend atmospherically
  instead of hard-cutting against the one behind
- MIRROR TILING (image + flipped copy) so motion_mirroring repeats with
  no seam, pixel-art safe — no crossfade mush
- transparent top padding so ParallaxLoader picks scale 1 for every
  layer (heights >= 254)

Output: assets/backgrounds/earth/layer_0..3.png. The generated Earth
layers (and the layer_4 car husks) are retired — the real plates carry
the scene now. fg_0 ground-cover silhouettes stay.

Run from Game/:  python tools/build_earth_backgrounds.py
"""

import os
from PIL import Image

SRC = os.path.join(os.path.dirname(__file__), "..", "assets", "backgrounds")
OUT = os.path.join(SRC, "earth")

MIN_H = 260  # ParallaxLoader picks integer scale 1 for heights >= 254


def load_half(name):
    im = Image.open(os.path.join(SRC, name)).convert("RGBA")
    return im.resize((im.width // 2, im.height // 2), Image.NEAREST)


def haze_fade(im, band):
    """Fade the top `band` rows content->transparent: atmospheric blend."""
    if band <= 0:
        return im
    px = im.load()
    for y in range(min(band, im.height)):
        t = y / band  # 0 at very top -> 1 at band bottom
        f = t * t * (3.0 - 2.0 * t)  # smoothstep
        for x in range(im.width):
            c = px[x, y]
            if c[3]:
                px[x, y] = (c[0], c[1], c[2], int(c[3] * f))
    return im


def pad_top(im, target_h):
    if im.height >= target_h:
        return im
    canvas = Image.new("RGBA", (im.width, target_h), (0, 0, 0, 0))
    canvas.paste(im, (0, target_h - im.height))
    return canvas


def mirror_tile(im):
    """Seamless repeat: original + horizontally flipped copy."""
    canvas = Image.new("RGBA", (im.width * 2, im.height), (0, 0, 0, 0))
    canvas.paste(im, (0, 0))
    canvas.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (im.width, 0))
    return canvas


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name))
    print("wrote earth/" + name, im.size)


def main():
    # layer_0 — the sky plate, opaque backdrop (no fade: it IS the back)
    sky = load_half("opening_sky.png")
    save(mirror_tile(sky), "layer_0.png")

    # layer_1 — the Wall on the horizon, hazed into the sky above it
    wall = haze_fade(load_half("opening_sky_and_wall.png"), 44)
    save(mirror_tile(pad_top(wall, MIN_H)), "layer_1.png")

    # layer_2 — pines + the car graveyard mid-field
    cars = haze_fade(load_half("opening_cars_and_trees.png"), 52)
    save(mirror_tile(pad_top(cars, MIN_H)), "layer_2.png")

    # layer_3 — near ground and wrecks, tight fade so it sits in the field
    ground = haze_fade(load_half("opening_ground_and_cars.png"), 22)
    save(mirror_tile(pad_top(ground, MIN_H)), "layer_3.png")

    # retire the generated near-props band — the real wrecks replace it
    old = os.path.join(OUT, "layer_4.png")
    for path in (old, old + ".import"):
        if os.path.exists(path):
            os.remove(path)
            print("removed", os.path.relpath(path, SRC))

    print("done")


if __name__ == "__main__":
    main()
