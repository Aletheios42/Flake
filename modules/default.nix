{ lib, ... }:
let
  discoveredDirs = [ ./core ./features ];

  discoverModules = dir:
    let
      entries = builtins.readDir dir;
      nixFiles = lib.filterAttrs (name: type:
        lib.hasSuffix ".nix" name && lib.match "default.nix" name == null && "regular" == type 
      ) entries;
    in
    map (name: dir + "/${name}") (lib.attrNames nixFiles);
in
{
  imports = lib.concatMap discoverModules discoveredDirs;
}
