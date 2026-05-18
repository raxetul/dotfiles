{ config, ... }:

# Git — daily-driver ergonomics, with GPG signing turned on iff a key
# has been provisioned by scripts/gpg-setup.sh (see home/modules/gpg.nix).
#
# * delta is enabled as the pager so diffs/log/blame pick up the
#   Catppuccin Mocha palette via the included gitconfig.
# * Commit / push / pull / rebase / merge defaults follow modern git
#   practice (rebase pull, autosetupremote, autostash, zdiff3, …).
# * commit.template points at a Conventional Commits skeleton; the
#   global hook template under ~/.config/git/template/ enforces the
#   format on every new repo this host clones.
# * Identity is selected by directory: personal under ~/personal/,
#   work under ~/workspace/ (existing behavior, kept intact).
# * Signing: this module does NOT set commit.gpgsign at the top level.
#   scripts/gpg-setup.sh generates a key and writes
#   ~/.config/git/signing.gitconfig with [user] signingkey + [commit]
#   gpgsign = true. That file is `include`d below, so signing turns on
#   only once a key actually exists — and the include is silent if the
#   file is missing, so a fresh host still commits cleanly.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
  homeDir     = config.home.homeDirectory;
in
{
  programs.git = {
    enable = true;
    delta.enable = true;

    settings = {
      user.name = "Emrah URHAN";
      user.email = "raxetul@gmail.com";

      init = {
        defaultBranch = "main";
        # Every `git init` and `git clone` seeds .git/hooks/ from this
        # directory — so the Conventional Commits guard travels with you.
        templateDir = "${homeDir}/.config/git/template";
      };

      pull.rebase = true;
      push.autoSetupRemote = true;

      rebase = {
        autoStash = true;
        autosquash = true;
      };

      merge.conflictStyle = "zdiff3";

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };

      fetch.prune = true;

      commit = {
        template = "${homeDir}/.config/git/commit-template";
        verbose = true;
      };
    };

    includes = [
      {
        condition = "gitdir:~/personal/";
        contents.user.email = "raxetul@gmail.com";
      }
      {
        condition = "gitdir:~/workspace/";
        contents.user.email = "emrahurhan@buyutech.com.tr";
      }
      {
        # Delta's Catppuccin Mocha palette — kept in configurations/ so it
        # can be edited without a home-manager switch.
        path = "${dotfilesDir}/configurations/themes/delta/catppuccin.gitconfig";
      }
      {
        # GPG signing config — written by scripts/gpg-setup.sh once a key
        # exists for this host's git email. Git's `include.path` is
        # silent on missing files, so this is safe to declare even before
        # the wizard has run.
        path = "${homeDir}/.config/git/signing.gitconfig";
      }
    ];
  };

  # Live links into the repo so edits take effect without a rebuild.
  xdg.configFile."git/commit-template".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/git/commit-template";

  xdg.configFile."git/template/hooks/commit-msg".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/configurations/git/template/hooks/commit-msg";

  xdg.configFile."git/template/hooks/pre-commit".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/configurations/git/template/hooks/pre-commit";
}
