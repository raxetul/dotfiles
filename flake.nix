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

      mkHome = { system, username, homeDirectory, profile }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit profile; };
          modules = [
            ./home
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "24.05";
            }
          ];
        };

      # All values below resolved at evaluation time. Requires --impure
      # (setup.sh passes it).
      currentSystem = builtins.currentSystem or "x86_64-linux";

      currentUser =
        let u = builtins.getEnv "USER"; in if u == "" then "user" else u;

      currentHome =
        let h = builtins.getEnv "HOME"; in
        if h != "" then h
        else if lib.hasSuffix "darwin" currentSystem
        then "/Users/${currentUser}"
        else "/home/${currentUser}";

      # Profile is set explicitly by setup.sh via $DOTFILES_PROFILE.
      # Default is "server" — pass `--desktop` to setup.sh (or export
      # DOTFILES_PROFILE=desktop) to include the Linux desktop bucket.
      # Ignored on macOS, where darwin.nix is always imported.
      currentProfile =
        let fromEnv = builtins.getEnv "DOTFILES_PROFILE"; in
        if fromEnv != "" then fromEnv else "server";
    in
    {
      homeConfigurations.default = mkHome {
        system = currentSystem;
        username = currentUser;
        homeDirectory = currentHome;
        profile = currentProfile;
      };

      # Exposed so power users can build a configuration for an
      # arbitrary identity without going through the impure path.
      lib.mkHome = mkHome;
    };
}
