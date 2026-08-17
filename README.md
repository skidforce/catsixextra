# catsixextra

Up-to-date mirror of the catsix/catvape script, cleaned up and self-hosted:

- All files verified ASCII-clean (no double-encoded UTF-8, no non-ASCII glyphs)
- Game scripts load per-place from `games/<PlaceId>.lua` (flat, like the original)
- GUI sanitizes any remaining mojibake in profile/config data on read
- Dead `_generated/` duplicates removed

## Usage

Paste `load-catsixextra.lua` into your executor and run. It downloads all
files to `catsixextra/` from this repo (raw.githubusercontent.com, no token
needed), then executes `main.lua`.

## Files

- `load-catsixextra.lua` - installer/loader (paste into executor)
- `main.lua` - entry point
- `init.lua` - legacy bootstrap used by the GUIs
- `guis/` - new / old / rise / liquidbounce / wurst GUIs
- `libraries/` - shared libraries
- `games/` - per-place scripts (`universal.lua` + `<PlaceId>.lua`, flat)
- `assets/` - icons and fonts
- `features.json` / `packages.json` - changelog / game data

## Updating

Runs of the loader always re-download everything, so the script auto-updates
on every use.