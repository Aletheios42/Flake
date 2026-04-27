{ pkgs, lib, config,  ... }:
{
  options.comunicacion.enable = lib.mkEnableOption "Paquetes para comunicarte por chat";

  config = lib.mkIf (config.comunicacion.enable) {
    userPackages.comunicacion =  [
      pkgs.discord pkgs.whatsie pkgs.slack pkgs.telegram-desktop pkgs.thunderbird
    ];
  };
}
