---
nix-file: home/modules/packages/linux-desktop.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# packages/linux-desktop

## Purpose

Linux GUI stack. Imported only when `profile == "desktop"` on
Linux. Everything here assumes a graphical session. Phase 8 made
Ghostty the default terminal; Phase 9 trimmed the bar/launcher
stack to Waybar + wofi.

## My preferences (why it's configured this way)

- **Ghostty as the terminal.** Phase 8 dropped `alacritty` and
  `wezterm`. The config lives at `~/.config/ghostty/config`
  (XDG path), shared with macOS.
- **Sway + Waybar + wofi**, not i3 / polybar / dmenu. Phase 9
  trimmed polybar; wofi replaces dmenu under Wayland.
- **`dunst` for notifications.** Catppuccin Mocha-themed via
  `configurations/dunst/dunstrc`, edits take effect on
  `dunst --reload`.
- **`flameshot` over the Sway-native screenshot tools.** Better
  annotation UX; works under XWayland.
- **Discord + Telegram via Nix.** Auto-updates with `nix flake
  update` instead of a manual cask bump.
- **`qtcreator` and `kdiff3` as Nix packages.** Both work fine
  outside the macOS app bundle ecosystem.

## Packages

### Terminal
- `ghostty`.

### Wayland / sway stack
- `sway`, `swaybg`, `swayidle`, `swaylock`.
- `waybar`, `wofi`, `dunst`, `xdotool`.

### Apps
- `flameshot`, `kdiff3`, `nautilus`, `obs-studio`,
  `smplayer`, `telegram-desktop`, `discord`, `veracrypt`,
  `qtcreator`.

### Recording / misc
- `asciinema`.

## Other declarations

- `programs.waybar.enable = true`.
- `xdg.configFile."dunst/dunstrc"` →
  `configurations/dunst/dunstrc`.
- `xdg.configFile."waybar/config.jsonc"` →
  `configurations/waybar/config.jsonc`.
- `xdg.configFile."waybar/style.css"` →
  `configurations/waybar/style.css`.

## Related

- [home/modules/ghostty.nix](../home/modules/ghostty.nix) —
  Ghostty config (imported here as well, on desktop profile).
- [configurations/waybar/](../configurations/waybar/) — bar
  config + Catppuccin Mocha CSS.
- [configurations/dunst/dunstrc](../configurations/dunst/dunstrc)
  — notification daemon.
- [doc/theming.md](theming.md).
