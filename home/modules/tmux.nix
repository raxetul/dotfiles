{ ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    keyMode = "vi";
    historyLimit = 50000;
    escapeTime = 10;
  };
}
