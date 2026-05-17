{ lib, profile, ... }:

# Linux-only bucket. The `profile` arg (server | desktop) is set by
# setup.sh via $DOTFILES_PROFILE and forwarded through extraSpecialArgs
# in flake.nix.
assert lib.elem profile [ "server" "desktop" ];

{
  imports =
    [ ./modules/packages/linux.nix ]
    ++ lib.optional (profile == "server")  ./modules/packages/linux-server.nix
    ++ lib.optionals (profile == "desktop") [
      ./modules/packages/linux-desktop.nix
      ./modules/ghostty.nix
    ];
}
