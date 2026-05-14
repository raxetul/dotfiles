{ pkgs, ... }:

# macOS-only additions. With Nix providing everything else, Darwin gets:
#   - colima as the Docker daemon backend (Nix `docker` is CLI-only)
#   - lima as the VM runtime colima depends on
{
  home.packages = with pkgs; [
    colima
    lima
  ];

  # Start colima manually with `colima start`. To run as a launchd agent
  # use `programs.colima` once it lands in home-manager, or add a
  # `~/Library/LaunchAgents` plist yourself.
}
