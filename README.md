# Pokegodex

Linux collectable terminal Pokédex that captures sprites from the external tool `pokego`, and shows them as your `fastfetch` logo on shell startup.

This repository provides a simple workflow to "catch" Pokemon rendered by `pokego`, keep a persistent pokédex, and view per-generation progress.

Fork of [poketerm](https://github.com/chris-wood-mo/poketerm) by chris-wood-mo — same catch tracking, shiny odds, XP, streaks, and achievements, just powered by [pokego](https://github.com/rubiin/pokego) (Go, faster) for sprites instead of `pokemon-colorscripts`, and `fastfetch` instead of `neofetch`/`hyfetch`. This fork also flattens the project: the upstream repo carried a `files/0.0.1` … `files/0.0.6` directory per release plus a migration script for upgrading between them. There's only one version of this fork, so that's gone — updating is just "pull the latest files and re-run the installer."

## Features

- Capture a random Pokemon sprite (normal or shiny) using `pokego`.
- Persist caught Pokemon to a user pokédex file.
- Keep per-generation ordering using the generation lists in `gen_files/`.
- View a generation-specific catch progress report, trainer profile, and achievements.

## Requirements

- [pokego](https://github.com/rubiin/pokego) — install separately, not managed by this installer
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) — install separately, not managed by this installer
- Python3
- Zsh
- readchar (`pip3 install -r requirements.txt`)

## Project layout

```
pokegodex/
├── install.sh          # installer / uninstaller
├── pokegodex          # the shell script hooked into ~/.zshrc: picks + catches a Pokemon, shows it via fastfetch
├── pokedex.py          # the `pokedex` command: browse your caught Pokemon, trainer profile, achievements
├── trainer.py          # XP, level, and streak bookkeeping used by pokegodex and pokedex.py
├── achievements.py     # achievement definitions and unlock checks
├── trainer.json        # default trainer profile (only copied in on first install)
├── requirements.txt
├── LICENSE
└── gen_files/
    ├── gen1_list.txt … gen8_list.txt   # canonical per-generation Pokemon name lists
```

No pre-baked sprite/API cache ships in the repo (the upstream one did, at ~22 MB). `pokedex.py` builds its own cache under `~/.local/share/pokegodex/cache/` the first time it needs a given Pokemon's sprite or PokeAPI data, so this stays a lot smaller to clone; the only cost is a brief PokeAPI fetch + `pokego` call the very first time you view each Pokemon in the `pokedex` viewer.

## Installation

1. Make sure `pokego` and `fastfetch` are installed and on your `$PATH` (`pokego --version` and `fastfetch --version` should both work).

2. Run the installer:

   ```bash
   sudo ./install.sh
   ```

   Or to only ever catch from a specific generation or range (default is all of 1-8):

   ```bash
   sudo ./install.sh --gen 1
   sudo ./install.sh --gen 2-5
   ```

This will:

- Copy `gen_files/`, `pokegodex`, `pokedex.py`, `trainer.py`, `achievements.py` to `$HOME/.local/share/pokegodex/`
- Seed `trainer.json` there on first install only (an update never resets your trainer profile)
- Symlink `/usr/local/bin/pokegodex` and `/usr/local/bin/pokedex`
- Print the line you need to add to your `~/.zshrc` to catch a Pokemon on every new shell

3. **The installer does not edit `~/.zshrc` for you.** It prints the exact line to add — either

   ```
   pokegodex
   ```

   or, if you installed with `--gen`, the matching `pokegodex --gen ...` line. Add that line yourself wherever you like in `~/.zshrc` (e.g. right where you already invoke `fastfetch`/`neofetch`, if you do), then `source ~/.zshrc`.

## Updating

There's no migration system anymore — just pull the latest files and re-run the installer:

```bash
git pull origin main
sudo ./install.sh
```

The installer is idempotent: it won't touch your `~/.zshrc` hook again if it's already there, and it won't overwrite your `trainer.json`, so your pokédex and progress are untouched.

## Usage

- Run the capture script (installed as `/usr/local/bin/pokedex`) to view your stored pokédex per generation:

  ```
  pokedex [GEN_NUM 1-8]
  ```

  Example:
  - `pokedex` (defaults to generation 1)
  - `pokedex 3` (shows generation 3 progress)
  - `pokedex -h`/`--help`/`help` (shows help)

- From the pokedex, press `p` for the Trainer Profile or `a` for Achievements.

- The capture behavior appended to your shell (see `~/.zshrc`) picks a random Pokemon from your selected generation range, renders it via `pokego --name <name>`, and:
  - adds it to your persistent pokedex file (if not already present)
  - marks random 1-in-4096 encounters as shiny (1-in-10 once that generation is fully caught)
  - awards XP, updates your catch streak, and checks for newly unlocked achievements
  - shows the sprite as your `fastfetch` logo for that shell session, on top of whatever `fastfetch` config/modules you already have

## Uninstalling

```bash
sudo ./install.sh --uninstall
```

This removes `$HOME/.local/share/pokegodex/` and the `/usr/local/bin` symlinks. Since the installer never touched `~/.zshrc`, there's nothing to restore there — just remove the `pokegodex` line you added yourself. `pokego` and `fastfetch` are left alone — they're tools you installed yourself, not something this installer manages.

## Notes

- The persistent pokedex is stored at `$HOME/.local/share/pokegodex/pokedex.txt` (the `POKEDEX_FILE` variable in the bundled script).
- The pokedex file is kept read-only (`chmod 444`) between runs, with a `sha256` integrity check, to make it harder to hand-edit; use `pokegodex --remove <name>` to take something out properly.

## Achievements

The list of achievements you can obtain are:

**Pokedex Milestones**
- First Pokemon Caught
- 50 Pokemon Caught
- 100 Pokemon Caught
- 905 Pokemon Caught
- HIDDEN
- Complete Generation 1
- Complete Generation 2
- Complete Generation 3
- Complete Generation 4
- Complete Generation 5
- Complete Generation 6
- Complete Generation 7
- Complete Generation 8
- HIDDEN

**Catch Achievements**
- 3 Day Catch Streak
- 7 Day Catch Streak
- 30 Day Catch Streak
- 100 Day Catch Streak
- 365 Day Catch Streak
- HIDDEN
- Caught 5 Shiny Pokemon
- Caught 100 Shiny Pokemon
- Caught 5 Pokemon in a day
- Caught 10 Pokemon in a day
- HIDDEN
- Caught a Pokemon 10 times
- Caught a Pokemon 25 times

**Level Milestones**
- Reach level 10
- Reach level 25
- HIDDEN
- Reach a total XP of 1000
- Reach a total XP of 10000
- Reach a total XP of 50000
- HIDDEN

**Special Collections**
- HIDDEN
- HIDDEN
- HIDDEN
- HIDDEN
- HIDDEN
- HIDDEN
- HIDDEN
- HIDDEN

There are 42 achievements in total for you to unlock. Some have been left hidden purposely so you can unlock them as you continue collecting!

## Credits

- All the Pokemon designs, names, branding etc. are trademarks of [The Pokemon Company](https://www.pokemon.com/uk)
- [poketerm](https://github.com/chris-wood-mo/poketerm) — the original project this is forked from; all catch/XP/achievement design is theirs
- [pokego](https://github.com/rubiin/pokego) for the sprites
- [PokeAPI](https://pokeapi.co/) for the data around the pokemon
