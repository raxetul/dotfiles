{ lib, pkgs, system, ... }:

# GPG / PGP — declarative agent + signing config, runtime key creation via
# scripts/gpg-setup.sh. Design:
#
#   * programs.gpg writes ~/.gnupg/gpg.conf with strong defaults (SHA-512,
#     AES-256, long key-IDs) so any key generated later already inherits a
#     modern crypto profile.
#   * gpg-agent.conf is small and platform-aware, so it's written inline
#     instead of symlinked. On macOS we point pinentry at the Homebrew
#     formula (pinentry-mac, declared in configurations/brew/Brewfile);
#     on Linux gpg-agent picks up pinentry-curses from PATH (installed
#     below).
#   * Git commit signing is set up in two layers:
#       1. home/modules/git.nix only `include`s
#          ~/.config/git/signing.gitconfig — it does NOT declare
#          commit.gpgsign / user.signingkey itself. Git's `include.path`
#          is silent on missing files, so a fresh host without keys
#          commits cleanly (unsigned).
#       2. scripts/gpg-setup.sh generates the key and writes that include
#          file with [user] signingkey + [commit] gpgsign = true + [tag]
#          gpgsign = true. Running the wizard flips signing on; never
#          running it leaves things unsigned but functional.
#
# OS detection follows the locked convention from the roadmap: derive
# `isDarwin` from the `system` specialArg via lib.hasSuffix, never from
# `pkgs.stdenv.isDarwin`.
let
  isDarwin = lib.hasSuffix "darwin" system;
  isLinux  = lib.hasSuffix "linux"  system;
in
{
  programs.gpg = {
    enable = true;

    settings = {
      # No "Welcome" banner; long key-IDs everywhere; fingerprints in
      # listings so the wizard can grep them out reliably.
      no-greeting          = true;
      keyid-format         = "long";
      with-fingerprint     = true;
      use-agent            = true;

      # Modern crypto preferences for all newly-generated keys.
      personal-cipher-preferences   = "AES256 AES192 AES";
      personal-digest-preferences   = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo              = "SHA512";
      s2k-digest-algo               = "SHA512";
      s2k-cipher-algo               = "AES256";

      charset = "utf-8";
    };
  };

  # ~/.gnupg/gpg-agent.conf — small + platform-aware, written inline.
  # Cache TTLs are a day so the pinentry prompt isn't a per-commit ritual.
  home.file.".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 86400
    max-cache-ttl     86400
    allow-loopback-pinentry
  '' + lib.optionalString isDarwin ''
    pinentry-program /opt/homebrew/bin/pinentry-mac
  '';

  # Pinentry: Linux gets it from Nix; macOS gets it from Homebrew (see
  # configurations/brew/Brewfile — pinentry-mac).
  home.packages = lib.optional isLinux pkgs.pinentry-curses;
}
