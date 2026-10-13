# Lifecycle animations

Four short animations show how the dotfiles move through their lifecycle.
Each animation is a flowchart. A dot travels along the arrows, and each step lights up when the dot arrives.
Source: [`lifecycle.py`](lifecycle.py) (ManimCE, no LaTeX). Palette: Catppuccin Mocha.

| GIF | Scene | Source of truth | What it shows |
| --- | --- | --- | --- |
| ![install](install.gif) | `Install` | `install.sh`, `setup.sh`, [light-profile.md](../light-profile.md) | `install.sh` clones `/opt/dotfiles`. `setup.sh` runs steps 1 to 7 on a Linux host. Then a `--light` run skips most steps. |
| ![update](update.gif) | `Update` | `scripts/update-dotfiles` | The packages layer on a macOS host, then the configurations layer. TPM and vim-plug install and prune (reconcile). |
| ![uninstall](uninstall.gif) | `Uninstall` | `scripts/uninstall.sh`, [state-management.md](../state-management.md) | The ledger drives steps 1 to 4. `--purge` and `--shell` are off by default. A second pass turns them on. |
| ![migrate](migrate-to-opt.gif) | `MigrateToOpt` | `scripts/migrate-to-opt.sh` | Dev checkout to `/opt/dotfiles`. The old checkout stays. |

## How to read a flowchart

The shapes mean the same in all four scenes. One legend line at the bottom of each GIF repeats them.

| Shape or colour | Meaning |
| --- | --- |
| Rounded rectangle | A step. The small number is the step number in the script. |
| Diamond | A decision. The arrows out of it carry a `yes` or `no` label. |
| Grey, dark node or arrow | Skipped. The path does not use it. It stays on screen. |
| Blue | Now. The dot is here, or just arrived. |
| Green | Done. The dot already passed. |

Rules for the drawing:

- The flow goes left to right, then turns down and goes back right to left (a snake path).
- A bypass arrow goes below or above the row. It skips the step in between.
- A skipped branch turns grey. It is never hidden.
- The colours are few: blue for now, green for done, grey for skipped. Text and background are neutral.

Decision diamonds in each scene:

| Scene | Decisions |
| --- | --- |
| `Install` | `--light?` (twice), `macOS?`, `in native repo?` |
| `Update` | `macOS?`, `in native repo?`, `tmux server runs?` |
| `Uninstall` | `in ledger?`, `--purge?`, `--shell?` |
| `MigrateToOpt` | `dirty?`, `same device?` |

## Render

Install manim with the native package manager. Do not add it to `packages/`.

```sh
brew install manim
```

Manim writes an unoptimised GIF of 30 to 60 MB. Render an mp4, then make the GIF with `ffmpeg`.
Each GIF must stay at or below 2 MB. Each GIF runs 12 to 30 seconds.

```sh
scene=Update; name=update          # also: Uninstall/uninstall, MigrateToOpt/migrate-to-opt
manim -ql -o "${name}.mp4" doc/animations/lifecycle.py "${scene}"
ffmpeg -y -i "media/videos/lifecycle/480p15/${name}.mp4" \
    -vf "fps=8,scale=768:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=32:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" \
    -loop 0 "doc/animations/${name}.gif"
```

`Install` is the longest scene. It uses a shorter beat (`pace = 0.7` in `lifecycle.py`).
For that scene use `scale=704:-1` and `max_colors=28`.
The `media/` folder is the manim cache. It is in `.gitignore`.
