# nix.sh — flake + home-manager day-to-day shortcuts.
alias nfu='nix flake update'
alias nfc='nix flake check'
alias nfm='nix flake metadata'

# home-manager switch from the repo flake — `--impure` is needed because
# flake.nix reads $USER / $HOME at evaluation time.
alias hms='nix run --impure home-manager/master -- switch --impure --flake .#default'

# Build a derivation without activating it (useful for `nix flake check`-
# adjacent local debugging).
alias nb='nix build'

# Garbage-collect old generations (keep the current one).
alias ngc='nix-collect-garbage -d'
