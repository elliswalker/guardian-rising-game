"""
One-time tool: extract individual character sprites from Guardian Rising bible sheets.
Run from the Game/ directory:  python extract_sprites.py
"""
from PIL import Image
import os

SPRITES_DIR = "assets/sprites"
BIBLE_DIR   = "assets/sprites"

BG_THRESHOLD = 45   # max(r,g,b) > this = character pixel
GAP_MIN      = 40   # px gap between characters


def _get_col_mask(pix, w, h, y1, y2):
    """Returns list[bool]: True for each column x that has a non-bg pixel in [y1,y2]."""
    mask = [False] * w
    for y in range(y1, y2):
        row_start = y * w
        for x in range(w):
            if mask[x]:
                continue
            r, g, b = pix[row_start + x]
            if max(r, g, b) > BG_THRESHOLD:
                mask[x] = True
    return mask


def _col_groups(mask):
    """Find contiguous True groups in mask, merge if gap < GAP_MIN."""
    groups = []
    in_g, start = False, 0
    for i, v in enumerate(mask):
        if v and not in_g:
            start, in_g = i, True
        elif not v and in_g:
            groups.append([start, i])
            in_g = False
    if in_g:
        groups.append([start, len(mask)])

    merged = []
    for g in groups:
        if merged and (g[0] - merged[-1][1]) < GAP_MIN:
            merged[-1][1] = g[1]
        else:
            merged.append(list(g))
    return merged


def _row_bounds(pix, w, col_s, col_e, y1, y2):
    """Find first and last row in [y1,y2] that has a character pixel in [col_s,col_e]."""
    r_top, r_bot = y2, y1
    for y in range(y1, y2):
        row_start = y * w
        for x in range(col_s, col_e):
            r, g, b = pix[row_start + x]
            if max(r, g, b) > BG_THRESHOLD:
                if y < r_top:
                    r_top = y
                if y + 1 > r_bot:
                    r_bot = y + 1
                break
    return r_top, r_bot


def extract(sheet_path, output_subdir, names, sizes,
            y_top_frac=0.22, y_bot_frac=0.82):
    img = Image.open(sheet_path).convert("RGB")
    w, h = img.size
    y1, y2 = int(h * y_top_frac), int(h * y_bot_frac)
    pix = list(img.getdata())

    col_mask = _get_col_mask(pix, w, h, y1, y2)
    groups = _col_groups(col_mask)

    if len(groups) < len(names):
        print(f"  WARNING: found {len(groups)} groups, expected {len(names)} for {os.path.basename(sheet_path)}")

    out_dir = os.path.join(SPRITES_DIR, output_subdir)
    os.makedirs(out_dir, exist_ok=True)

    for idx, (name, target) in enumerate(zip(names, sizes)):
        if idx >= len(groups):
            print(f"  SKIP {name}: not enough groups found")
            continue
        col_s, col_e = groups[idx]
        r_top, r_bot = _row_bounds(pix, w, col_s, col_e, y1, y2)
        if r_bot <= r_top:
            print(f"  SKIP {name}: empty row bounds")
            continue

        crop = img.crop((col_s, r_top, col_e, r_bot))
        tw, th = target
        scaled = crop.resize((tw, th), Image.NEAREST)
        out_path = os.path.join(out_dir, f"{name}.png")
        scaled.save(out_path)
        print(f"  {name}.png  {crop.width}x{crop.height} -> {tw}x{th}")


print("-- Fallen --")
extract(
    os.path.join(BIBLE_DIR, "guardian-rising-fallen-sprites.png"),
    "enemies/fallen",
    ["dreg", "vandal", "captain", "shank", "servitor"],
    [(12,20), (18,26), (22,34), (18,14), (28,28)],
)

print("-- Hive --")
extract(
    os.path.join(BIBLE_DIR, "guardian-rising-hive-sprites.png"),
    "enemies/hive",
    ["thrall", "cursed_thrall", "acolyte", "knight", "wizard"],
    [(12,16), (12,16), (16,24), (22,34), (18,30)],
)

print("-- Cabal --")
extract(
    os.path.join(BIBLE_DIR, "guardian-rising-cabal-sprites.png"),
    "enemies/cabal",
    ["psion", "legionary", "centurion", "phalanx"],
    [(12,22), (18,28), (22,32), (24,30)],
)

print("-- Vex --")
extract(
    os.path.join(BIBLE_DIR, "guardian-rising-vex-sprites.png"),
    "enemies/vex",
    ["goblin", "hobgoblin", "harpy", "minotaur", "hydra"],
    [(14,22), (16,26), (16,14), (24,32), (30,28)],
)

print("-- Player --")
extract(
    os.path.join(BIBLE_DIR, "guardian-rising-player-sprites.png"),
    "player",
    ["speaker", "ghost", "hunter", "titan", "warlock"],
    [(28,28), (16,16), (18,26), (22,34), (24,28)],
    y_top_frac=0.28, y_bot_frac=0.80,
)

print("Done.")
