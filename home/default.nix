{ lib, system, ... }:

# Pure dispatcher — selects platform-specific bundles by string-suffixing
# `system`. Every host loads ./common.nix; Linux hosts add ./linux.nix and
# macOS hosts add ./darwin.nix. Profile-based filtering (server vs desktop)
# happens one level deeper, inside ./linux.nix.
let
  isDarwin = lib.hasSuffix "darwin" system;
  isLinux  = lib.hasSuffix "linux"  system;
in
{
  imports =
    [ ./common.nix ]
    ++ lib.optional isDarwin ./darwin.nix
    ++ lib.optional isLinux  ./linux.nix;
}
