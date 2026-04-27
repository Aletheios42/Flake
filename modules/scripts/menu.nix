{ pkgs, lib, ... }:
nombre: menu: let
configFile = pkgs.writeText "${nombre}-config.yaml"
(lib.generators.toYAML {} {
  anchor = "bottom-right";
  inherit menu;
});
in
pkgs.writeShellScriptBin nombre ''
    exec ${lib.getExe pkgs.wlr-which-key} ${configFile}
  ''
