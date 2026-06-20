{ lib, ... }:
let
  discoveredDirs = [ ./core ./programs ./services ./infra ./scripts ];

  excludedFiles = [ "menu.nix" ];

  discoverModules = dir:
    let
      entries = builtins.readDir dir;
      nixFiles = lib.filterAttrs (name: type:
        lib.hasSuffix ".nix" name
        && lib.match "default.nix" name == null
        && ! (lib.elem name excludedFiles)
        && "regular" == type
      ) entries;
    in
    map (name: dir + "/${name}") (lib.attrNames nixFiles);
in
{
  imports = lib.concatMap discoverModules discoveredDirs;
}
