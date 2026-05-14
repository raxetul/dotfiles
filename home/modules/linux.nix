{ ... }:

# Linux-specific bits. Group memberships and systemd service enablement
# from the old setups/user.zsh are system-level and must still be applied
# by setup.sh — Home Manager runs unprivileged and cannot touch /etc.
{
  home.sessionVariables = {
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  };
}
