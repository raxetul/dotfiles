{ pkgs, ... }:

# macOS-only packages — both CLI and desktop, installed on every Darwin
# host (macOS is essentially always graphical, so there's no server vs.
# desktop split here).
{
  home.packages = with pkgs; [
    # Container daemon — pkgs.docker on Darwin is CLI-only; colima + lima
    # provide the daemon backend. Run `colima start` once after install.
    colima
    lima
  ];
}
