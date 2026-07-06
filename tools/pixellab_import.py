"""Import a PixelLab rotation into the game's sprite convention (#49).

Downloads a rotation PNG (east-facing), trims transparent padding, saves
as <out>_right.png and a mirrored <out>_left.png. Matches the convention
the approved Pro sprites use.

Usage (from Game/):
    python tools/pixellab_import.py <east_url> <out_base_path>
e.g.
    python tools/pixellab_import.py https://.../east.png assets/sprites/enemies/fallen/vandal
"""

import io
import sys
import urllib.request

from PIL import Image


def main():
    url, out_base = sys.argv[1], sys.argv[2]
    req = urllib.request.Request(url, headers={"User-Agent": "guardian-rising-import"})
    data = urllib.request.urlopen(req, timeout=60).read()
    im = Image.open(io.BytesIO(data)).convert("RGBA")
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    im.save(out_base + "_right.png")
    im.transpose(Image.FLIP_LEFT_RIGHT).save(out_base + "_left.png")
    print(f"{out_base}_right/left.png {im.size}")


if __name__ == "__main__":
    main()
