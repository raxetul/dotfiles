{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "aws"
        "kubectl"
        "nodenv"
      ];
    };

    # Third-party plugins. On first build, Nix will report the correct
    # `sha256` for each placeholder — replace lib.fakeSha256 with the value
    # it prints. Pin to a specific rev when you do.
    plugins = [
      {
        name = "enhancd";
        src = pkgs.fetchFromGitHub {
          owner = "babarot";
          repo = "enhancd";
          rev = "v2.5.1";
          sha256 = pkgs.lib.fakeSha256;
        };
        file = "init.sh";
      }
      {
        name = "zsh-histdb";
        src = pkgs.fetchFromGitHub {
          owner = "larkery";
          repo = "zsh-histdb";
          rev = "main";
          sha256 = pkgs.lib.fakeSha256;
        };
      }
      {
        name = "alias-tips";
        src = pkgs.fetchFromGitHub {
          owner = "djui";
          repo = "alias-tips";
          rev = "master";
          sha256 = pkgs.lib.fakeSha256;
        };
      }
    ];

    initContent = ''
      setopt prompt_subst
      zle_highlight=(bold)

      export HISTORY_IGNORE="(ls|cat|AWS|SECRET|PASSWORD|TOKEN|API|KEY|PASS|SECRETS|SECRET_KEY|SECRET_TOKEN|SECRET_KEY_BASE|SECRET_TOKEN_BASE)"

      zshaddhistory() {
        emulate -L zsh
        [[ $1 != ''${~HISTORY_IGNORE} ]]
      }

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666611,bg=black,bold,underline"

      export ENHANCD_FILTER="fzf --height 40%:fzy"
    '';
  };
}
