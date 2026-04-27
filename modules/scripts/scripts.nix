{ pkgs, ... }:
let
  scriptsDir = ./.;
  scripts = map (name: pkgs.writeShellScriptBin
    (builtins.replaceStrings [".sh"] [""] name)
    (builtins.readFile (scriptsDir + "/${name}"))
  ) (builtins.filter
    (name: builtins.match ".*\\.sh" name != null)
    (builtins.attrNames (builtins.readDir scriptsDir))
  );
in
{ userPackages.scripts = scripts; }
