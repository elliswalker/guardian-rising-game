"""Shared style engine for all sprite generators (GH #38).

Implements the finish pass from Design/Art Direction.md — the K2C rule
"one light: the sky":

- every sky-facing edge pixel gets a 1px rim light
- every ground-facing edge pixel gets a 1px contact shade
- saturated pixels are MEANING (glimmer blue, faction glows, embers,
  lamps) and are never touched

Applied uniformly, this is what makes two dozen separately-drawn sprites
read as one game: they all agree where the light comes from, so the
day/night modulate tint lands on a consistent lighting model.

Usage in a generator:  from sprite_style import finish
then call finish(im) inside save() before writing the PNG.
"""

RIM = 1.20     # sky-facing edge brightness
SHADE = 0.84   # ground-facing edge darkness


def _is_accent(c):
    """Saturated = meaningful (glow/energy/ember). Leave it alone."""
    return max(c[0], c[1], c[2]) - min(c[0], c[1], c[2]) > 60


def finish(im, rim=RIM, shade=SHADE):
    """One light, the sky: rim-light top edges, shade ground contacts."""
    w, h = im.size
    src = im.load()

    def alpha(x, y):
        if 0 <= x < w and 0 <= y < h:
            return src[x, y][3]
        return 0

    ops = []
    for y in range(h):
        for x in range(w):
            c = src[x, y]
            if c[3] == 0 or _is_accent(c):
                continue
            if alpha(x, y - 1) == 0:
                ops.append((x, y, rim))
            elif y == h - 1 or alpha(x, y + 1) == 0:
                ops.append((x, y, shade))
    for x, y, f in ops:
        c = src[x, y]
        src[x, y] = (
            min(255, int(c[0] * f)),
            min(255, int(c[1] * f)),
            min(255, int(c[2] * f)),
            c[3],
        )
    return im
