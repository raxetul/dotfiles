# Lifecycle animations

Four short animations show how the dotfiles move through their lifecycle.
Source: [`lifecycle.py`](lifecycle.py) (ManimCE, no LaTeX). Palette: Catppuccin Mocha.

| GIF | Scene | Source of truth | What it shows |
| --- | --- | --- | --- |
| ![install](install.gif) | `Install` | `install.sh`, `setup.sh`, [light-profile.md](../light-profile.md) | `install.sh` clones `/opt/dotfiles`. `setup.sh` runs steps 1 to 7. Then `--light` greys the skipped steps. |
| ![update](update.gif) | `Update` | `scripts/update-dotfiles` | The packages layer, then the configurations layer. TPM and vim-plug install and prune (reconcile). |
| ![uninstall](uninstall.gif) | `Uninstall` | `scripts/uninstall.sh`, [state-management.md](../state-management.md) | The ledger drives steps 1 to 4. `--purge` and `--shell` are off by default. |
| ![migrate](migrate-to-opt.gif) | `MigrateToOpt` | `scripts/migrate-to-opt.sh` | Dev checkout to `/opt/dotfiles`. The old checkout stays. |

Card colours:

| Colour | Meaning |
| --- | --- |
| Green | Step runs. |
| Grey | Step is skipped. |
| Yellow | Step runs in part, or only on request. |
| Peach | Plugin reconcile (install and prune). |
| Blue | Ledger, or a step done by another script. |

## Render

Install manim with the native package manager. Do not add it to `packages/`.

```sh
brew install manim
```

Manim writes an unoptimised GIF of 30 to 60 MB. Render an mp4, then make the GIF with `ffmpeg`.
Each GIF must stay at or below 2 MB.

```sh
scene=Install; name=install        # also: Update/update, Uninstall/uninstall, MigrateToOpt/migrate-to-opt
manim -ql -o "${name}.mp4" doc/animations/lifecycle.py "${scene}"
ffmpeg -y -i "media/videos/lifecycle/480p15/${name}.mp4" \
    -vf "fps=10,split[a][b];[a]palettegen=max_colors=40:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" \
    -loop 0 "doc/animations/${name}.gif"
```

`Install` is the longest scene. For that scene use `fps=8,scale=768:-1:flags=lanczos` and `max_colors=32`.
The `media/` folder is the manim cache. It is in `.gitignore`.
