{
  description = "raxetul/dotfiles — portable user environment via Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;

      mkHome = { system, username, homeDirectory }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [
            ./home
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "24.05";
            }
          ];
        };

      # Resolve the current user/system at evaluation time. This requires
      # `--impure` (setup.sh passes it) but eliminates the need to register
      # users statically in the flake.
      currentSystem = builtins.currentSystem or "x86_64-linux";
      currentUser =
        let u = builtins.getEnv "USER"; in if u == "" then "user" else u;
      currentHome =
        let h = builtins.getEnv "HOME"; in
        if h != "" then h
        else if lib.hasSuffix "darwin" currentSystem
        then "/Users/${currentUser}"
        else "/home/${currentUser}";
    in
    {
      homeConfigurations.default = mkHome {
        system = currentSystem;
        username = currentUser;
        homeDirectory = currentHome;
      };

      # Exposed so power users can build a configuration for an
      # arbitrary identity without going through the impure path.
      lib.mkHome = mkHome;
    };
}
