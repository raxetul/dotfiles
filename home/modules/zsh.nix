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

    plugins = [
      {
        name = "zsh-histdb";
        src = pkgs.zsh-histdb;
        file = "share/zsh-histdb/sqlite-history.zsh";
      }
      {
        name = "you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
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
    '';
  };
}
