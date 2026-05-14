{ ... }:

# Linux baseline — imported on every Linux host, regardless of profile.
# Server-specific tools (qemu, libvirt, …) live in linux-server.nix;
# GUI / desktop bits live in linux-desktop.nix.
{
  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  };
}
