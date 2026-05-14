{ pkgs, ... }:

# Linux CLI / system tools — installed on every Linux host, server or
# desktop. GUI apps live in linux-desktop.nix.
#
# Binaries only: `dockerd`, `libvirtd`, and group memberships still need
# root via your distro on non-NixOS hosts.
{
  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  };

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
