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
    qemu
    libvirt
    bridge-utils
    hdparm
    dstat
  ];
}
