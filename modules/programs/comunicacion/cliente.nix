{ pkgs, lib, config, ... }:
{
  options.comunicacion.cliente = lib.mkEnableOption "Descarga paquetes basicos de comunicacion";

  config = lib.mkIf (config.comunicacion.cliente) {
    userPackages.comunicacion = [
      pkgs.discord
      pkgs.whatsie
      (pkgs.symlinkJoin {
        name = "slack-dark";
        paths = [ pkgs.slack ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/slack \
            --add-flags "--force-dark-mode"
        '';
      })
      pkgs.telegram-desktop
      pkgs.weechat
      pkgs.element-desktop
    ];

    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
      directories = [
        { directory = ".config/discord"; mode = "0700"; }
        { directory = ".config/WhatSie"; mode = "0700"; }
        { directory = ".local/share/org.keshavnrj.ubuntu"; mode = "0700"; }
        { directory = ".config/Slack"; mode = "0700"; }
        { directory = ".config/telegram-desktop"; mode = "0700"; }
        { directory = ".local/share/TelegramDesktop"; mode = "0700"; }
        { directory = ".weechat"; mode = "0700"; }
        { directory = ".config/Element"; mode = "0700"; }
      ];
    };
  };
}
