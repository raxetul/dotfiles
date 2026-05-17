{ ... }:

# eza — the modern `ls`. The Catppuccin Mocha palette is exposed via
# EZA_COLORS rather than a theme file (eza reads the env on every run).
# The yml under configurations/themes/eza/ is the human-readable
# reference; the actual value below is kept in sync with it.
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--icons=auto"
    ];
  };

  home.sessionVariables.EZA_COLORS = builtins.concatStringsSep ":" [
    "uu=38;2;205;214;244"
    "gu=38;2;205;214;244"
    "da=38;2;180;190;254"
    "sb=38;2;249;226;175"
    "sn=38;2;205;214;244"
    "di=38;2;137;180;250;1"
    "ex=38;2;166;227;161;1"
    "ln=38;2;245;194;231"
    "lc=38;2;245;194;231"
    "pi=38;2;249;226;175"
    "so=38;2;249;226;175"
    "bd=38;2;243;139;168"
    "cd=38;2;243;139;168"
    "or=38;2;243;139;168;1"
    "xx=38;2;127;132;156"
  ];
}
