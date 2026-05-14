{ pkgs, ... }:

# Linux server tools — imported only when profile == "server" on Linux.
# CLI / env settings that apply to every Linux host (server or desktop)
# live in linux.nix; GUI apps live in linux-desktop.nix.
#
# Binaries only: `dockerd`, `libvirtd`, and group memberships still need
# root via your distro on non-NixOS hosts.
{
  home.packages = with pkgs; [
    # qemu_full bundles the firmware blobs (edk2-aarch64-code.fd,
    # edk2-arm-code.fd, OVMF, …) that on Debian/Ubuntu live in separate
    # `qemu-efi-arm` / `qemu-efi-aarch64` packages. Single Nix package =
    # same install on every distro.
    qemu_full
    libvirt
    bridge-utils
    hdparm
    dstat
  ];
}
