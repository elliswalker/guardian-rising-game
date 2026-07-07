"""Compose Pro-era parallax layers for Cosmodrome, Moon and Mars (#44).

Strategy: PixelLab can't produce 1900px seamless plates, so we marry the
two systems — the seamless generated skies/ridges (gen_parallax_backgrounds)
carry the tiling, and Pro LANDMARK sprites (assets/backgrounds/_landmarks/)
are composited onto the landmark layer, haze-tinted toward the sky so they
sit at distance. Landmarks are placed away from the tile seam.

Also upgrades the Earth foreground with the approved car wrecks as
near-black silhouettes (Ellis: cars go to the foreground).

Run AFTER gen_parallax_backgrounds.py, from Game/:
    python tools/build_planet_backgrounds.py
"""

import os
from PIL import Image

import gen_parallax_backgrounds as gp
from sprite_style import finish

GAME = os.path.join(os.path.dirname(__file__), "..")
LAND = os.path.join(GAME, "assets", "backgrounds", "_landmarks")
OUT = os.path.join(GAME, "assets", "backgrounds")
W, H = gp.W, gp.H


def load_scaled(name, target_h):
    im = Image.open(os.path.join(LAND, name)).convert("RGBA")
    s = target_h / im.height
    return im.resize((max(1, round(im.width * s)), target_h), Image.NEAREST)


def haze(im, color, strength):
    """Push a sprite toward the sky color — atmospheric distance."""
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (
                round(r + (color[0] - r) * strength),
                round(g + (color[1] - g) * strength),
                round(b + (color[2] - b) * strength),
                a,
            )
    return out


def paste_grounded(layer, sprite, x, ground_y):
    """Bottom-anchor a landmark at x (its left edge), feet on ground_y."""
    layer.alpha_composite(sprite, (x, ground_y - sprite.height))


def save(im, planet, name):
    finish(im, rim=1.12, shade=1.0)
    im.save(os.path.join(OUT, planet, name))
    print("wrote", planet + "/" + name)


def cosmodrome():
    # layer_2: bench + colony ship + gantries (replaces the hand-drawn set)
    im = gp.canvas()
    gp.ridge_ramped(im, 146, 5, [(2, 1.0), (5, 0.4)], (80, 74, 76, 255))
    sky = (172, 158, 146)
    ship = haze(load_scaled("cosmodrome_ship.png", 78), sky, 0.30)
    paste_grounded(im, ship, 130, 158)
    gantry = haze(load_scaled("cosmodrome_gantry.png", 90), sky, 0.38)
    paste_grounded(im, gantry, 30, 156)
    paste_grounded(im, gantry.transpose(Image.FLIP_LEFT_RIGHT), 252, 156)
    save(im, "cosmodrome", "layer_2.png")


def moon():
    # layer_2: regolith bench + three colossal bone spires
    im = gp.canvas()
    gp.ridge_ramped(im, 148, 5, [(3, 1.0), (8, 0.4)], (46, 48, 64, 255))
    sky = (26, 28, 44)
    spire = load_scaled("moon_spire.png", 96)
    for x, hgt, flip in [(36, 96, False), (150, 70, True), (250, 84, False)]:
        sp = load_scaled("moon_spire.png", hgt)
        if flip:
            sp = sp.transpose(Image.FLIP_LEFT_RIGHT)
        paste_grounded(im, haze(sp, sky, 0.22), x, 160)
    save(im, "moon", "layer_2.png")


def mars():
    # layer_1: mesas at heavy haze; layer_2: bench + landed warships
    im = gp.canvas()
    gp.ridge_ramped(im, 110, 10, [(2, 1.0), (4, 0.5)], (132, 88, 64, 255))
    sky1 = (206, 150, 110)
    mesa = haze(load_scaled("mars_mesa.png", 72), sky1, 0.42)
    paste_grounded(im, mesa, 42, 128)
    paste_grounded(im, mesa.transpose(Image.FLIP_LEFT_RIGHT), 196, 124)
    save(im, "mars", "layer_1.png")

    im = gp.canvas()
    gp.ridge_ramped(im, 146, 5, [(3, 1.0), (6, 0.4)], (98, 64, 52, 255))
    sky2 = (196, 140, 104)
    warship = haze(load_scaled("mars_warship.png", 64), sky2, 0.26)
    paste_grounded(im, warship, 52, 156)
    paste_grounded(im, warship.transpose(Image.FLIP_LEFT_RIGHT), 216, 158)
    save(im, "mars", "layer_2.png")


def earth_foreground_cars():
    # Ellis verdict: the car wrecks live in the FOREGROUND — near-black
    # silhouettes riding the fg strip in front of the action.
    fg_path = os.path.join(OUT, "earth", "fg_0.png")
    fg = Image.open(fg_path).convert("RGBA")
    for name, x, hgt in [("pro_car_a.png", 40, 16), ("pro_car_b.png", 210, 15)]:
        car = Image.open(os.path.join(GAME, "assets", "sprites", "world", name)).convert("RGBA")
        s = hgt / car.height
        car = car.resize((round(car.width * s), hgt), Image.NEAREST)
        car = haze(car, (16, 19, 26), 0.82)  # near-black, blue-cold
        fg.alpha_composite(car, (x, fg.height - 3 - hgt))
    fg.save(fg_path)
    print("wrote earth/fg_0.png (+car silhouettes)")


if __name__ == "__main__":
    cosmodrome()
    moon()
    mars()
    earth_foreground_cars()
    print("done")
