{ lib, ... }:

# Installs every file under ../../scripts/ to ~/.scripts/<name> and adds
# ~/.scripts to PATH. Drop a new file in the scripts/ folder and re-run
# setup.sh — home-manager picks it up automatically.
#
# Hidden files and README* are skipped. Sub-directories aren't recursed
# (flat folder only). Each installed file is marked executable.
let
  scriptsDir = ../../scripts;

  entries = builtins.readDir scriptsDir;

  scriptNames = lib.filter
    (n:
      entries.${n} == "regular"
      && !(lib.hasPrefix "." n)
      && !(lib.hasPrefix "README" n))
    (builtins.attrNames entries);

  toFile = name: {
    name = ".scripts/${name}";
    value = {
      source = scriptsDir + "/${name}";
      executable = true;
    };
  };
in
{
  home.file = lib.listToAttrs (map toFile scriptNames);
  home.sessionPath = [ "$HOME/.scripts" ];
}
