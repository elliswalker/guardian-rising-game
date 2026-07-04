# Parallax Backgrounds — drop-in convention

Put PNG layers here and they appear in-game automatically. No scene edits.

## How

1. Make a folder per planet: `earth/`, `cosmodrome/`, `moon/`, `mars/`
2. Drop layer PNGs named so they **sort far-to-near**:
   - `layer_0.png` — farthest (sky detail, celestial bodies — scrolls slowest)
   - `layer_1.png` — distant silhouettes (mountains, city wall, skyline)
   - `layer_2.png` — mid trees / structures
   - `layer_3.png` — near treeline (scrolls fastest)
3. Run the game. Layers auto-repeat horizontally, bottom-align to the
   horizon, pixel-snap scale (320×180-class packs render at 2×), and tint
   with the time of day like everything else.

Any count of layers works (1–6 sensible). No PNGs = flat-color sky as now.

## Licensing — the repo is PUBLIC

- **CC0 packs** (Kenney, Foozle, most of brullov/ansimuz's free packs —
  check each page): fine to commit right here.
- **Paid / no-redistribution packs**: put them in
  `assets/backgrounds_licensed/<planet>/` instead — that folder is
  gitignored. The loader checks both locations.

## Recommended starting packs (itch.io)

| Planet | Pack idea | Mood |
|---|---|---|
| earth | "Oak Woods" (brullov) or Ansimuz "Sunny Land" | forest ruins, Last City wall vibes |
| cosmodrome | Foozle "Void" environments (CC0) | rusted sci-fi, grey-blue |
| moon | Ansimuz "Gothicvania" (dark sets) | black sky, bone spires |
| mars | any dusty-red desert sidescroller set | dunes, war haze |

Search terms: "pixel sidescroller parallax", "pixel art background layers".
