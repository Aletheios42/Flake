{ pkgs, lib, config,  ... }:
{
  options.comunicacion = {
    enable = lib.mkEnableOption "Paquetes para comunicarte por chat";
    discord = lib.mkEnableOption "Activa discord";
    whatsie = lib.mkEnableOption "Activa whatsapp";
    slack = lib.mkEnableOption "Activa slack";
    telegram = lib.mkEnableOption "Activa telegram";
    thunderbird = lib.mkEnableOption "Activa thunderbird";
    weechat = lib.mkEnableOption "Activa weechat";
    element = lib.mkEnableOption "Activa element";
  };

  config = lib.mkIf config.comunicacion.enable (lib.mkMerge [
    (lib.mkIf config.comunicacion.discord {
      userPackages.comunicacion = [ pkgs.discord ];
    })
    (lib.mkIf config.comunicacion.whatsie {
      userPackages.comunicacion = [ pkgs.whatsie ];
    })
    (lib.mkIf config.comunicacion.slack {
      userPackages.comunicacion = [ pkgs.slack ];
    })
    (lib.mkIf config.comunicacion.telegram {
      userPackages.comunicacion = [ pkgs.telegram-desktop ];
    })
    (lib.mkIf config.comunicacion.thunderbird {
      userPackages.comunicacion = [ pkgs.thunderbird ];
    })
    (lib.mkIf config.comunicacion.weechat {
      userPackages.comunicacion = [ pkgs.weechat ];
    })
    (lib.mkIf config.comunicacion.element {
      userPackages.comunicacion = [ pkgs.element-desktop ];
    })
  ]);
}
