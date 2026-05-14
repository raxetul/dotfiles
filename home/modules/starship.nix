{ ... }:

# Replaces bullet-train.zsh. Approximates the previous prompt:
#   line 1: time, context (user@host), pwd
#   line 2: git, k8s context
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      format = ''
        $time$username$hostname$directory
        $git_branch$git_status$kubernetes$character
      '';

      time = {
        disabled = false;
        format = "[ $time ]($style) ";
        style = "bg:red fg:black";
        time_format = "%H:%M:%S";
      };

      username = {
        show_always = true;
        format = "[ $user ]($style)";
        style_user = "bg:yellow fg:black";
        style_root = "bg:yellow fg:black";
      };

      hostname = {
        ssh_only = false;
        format = "[@$hostname ]($style)";
        style = "bg:yellow fg:black";
      };

      directory = {
        format = "[ $path ]($style)";
        style = "bg:blue fg:black";
        truncation_length = 4;
        truncate_to_repo = false;
      };

      git_branch = {
        format = "[ $symbol$branch ]($style)";
        symbol = " ";
        style = "bg:white fg:black";
      };

      git_status = {
        format = "[$all_status$ahead_behind ]($style)";
        style = "bg:white fg:black";
        conflicted = "═";
        ahead = "⬆";
        behind = "⬇";
        diverged = "⬍";
        renamed = "➜";
        modified = "✘";
        clean = "✔";
      };

      kubernetes = {
        disabled = false;
        format = "[ $context ]($style)";
        style = "bg:cyan fg:black";
      };

      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };
    };
  };
}
