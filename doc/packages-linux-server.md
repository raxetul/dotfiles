---
nix-file: home/modules/packages/linux-server.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# packages/linux-server

## Purpose

Linux server tools. Imported only when `profile == "server"` on
Linux. Binaries only — group memberships and `dockerd`/`libvirtd`
service activation are still your distro's responsibility on
non-NixOS hosts.

## My preferences (why it's configured this way)

- **`qemu_full`, not piecemeal.** Distros split QEMU into
  per-architecture firmware blobs (`qemu-efi-arm`,
  `qemu-efi-aarch64`, `ovmf`, …); the Nix `qemu_full` package
  bundles them. One install path everywhere.
- **`libvirt` + `bridge-utils` for bridged-VM setups.** Sufficient
  for virsh-driven KVM hosts.
- **`hdparm` + `dstat`** for disk perf checks and live system
  metrics. Lightweight enough to leave on every server.

## Packages

- `qemu_full` — KVM + firmware blobs.
- `libvirt` — virsh + libvirtd CLI.
- `bridge-utils` — `brctl`.
- `hdparm` — disk timing / hdd config.
- `dstat` — combined sysstat dashboard.

## Related

- [home/modules/packages/linux-desktop.nix](../home/modules/packages/linux-desktop.nix)
  — the other Linux profile.
- [home/linux.nix](../home/linux.nix) — profile dispatcher.
