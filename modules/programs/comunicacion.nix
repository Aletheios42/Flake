{ pkgs, lib, config, ... }:
let
  user = config.vars.usuarioPrincipal;
  thunderbirdPrefs = ''
    user_pref("ui.systemUsesDarkTheme", 1);
    user_pref("browser.theme.content-theme", 0);
    user_pref("browser.theme.toolbar-theme", 0);
    user_pref("extensions.activeThemeID", "thunderbird-compact-dark@mozilla.org");
  '';
in
{
  options.comunicacion = {
    enable      = lib.mkEnableOption "Paquetes para comunicarte por chat";
    discord     = lib.mkEnableOption "Activa discord";
    whatsie     = lib.mkEnableOption "Activa whatsapp";
    slack       = lib.mkEnableOption "Activa slack";
    telegram    = lib.mkEnableOption "Activa telegram";
    thunderbird = lib.mkEnableOption "Activa thunderbird";
    weechat     = lib.mkEnableOption "Activa weechat";
    element     = lib.mkEnableOption "Activa element";
  };

  config = lib.mkIf config.comunicacion.enable (lib.mkMerge [
    (lib.mkIf config.comunicacion.discord {
      userPackages.comunicacion = [ pkgs.discord ];
      myImpermanence.users.${user}.directories = [ ".config/discord" ];
    })
    (lib.mkIf config.comunicacion.whatsie {
      userPackages.comunicacion = [ pkgs.whatsie ];
    })
    (lib.mkIf config.comunicacion.slack {
      userPackages.comunicacion = [
        (pkgs.symlinkJoin {
          name = "slack-dark";
          paths = [ pkgs.slack ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/slack \
              --add-flags "--force-dark-mode"
          '';
        })
      ];
      myImpermanence.users.${user}.directories = [ ".config/Slack" ];
    })
    (lib.mkIf config.comunicacion.telegram {
      userPackages.comunicacion = [ pkgs.telegram-desktop ];
      myImpermanence.users.${user}.directories = [ ".config/telegram-desktop" ];
    })
    (lib.mkIf config.comunicacion.thunderbird {
      userPackages.comunicacion = [ pkgs.thunderbird ];

      system.activationScripts.thunderbird-dark = {
        deps = [ "users" ];
        text = ''
          TB_DIR="/home/${user}/.thunderbird"
          if [ -d "$TB_DIR" ]; then
            PROFILE_PATH=$(${pkgs.gnugrep}/bin/grep -E '^Path=' "$TB_DIR/profiles.ini" 2>/dev/null | head -1 | cut -d= -f2)
            if [ -n "$PROFILE_PATH" ] && [ -d "$TB_DIR/$PROFILE_PATH" ]; then
              USER_JS="$TB_DIR/$PROFILE_PATH/user.js"
              # Solo escribir si no tiene ya nuestro marcador
              if ! ${pkgs.gnugrep}/bin/grep -q "thunderbird-compact-dark" "$USER_JS" 2>/dev/null; then
                cat >> "$USER_JS" << 'TBEOF'
${thunderbirdPrefs}TBEOF
              fi
            fi
          fi
        '';
      };

      myImpermanence.users.${user}.directories = [ ".thunderbird" ];
    })
    (lib.mkIf config.comunicacion.weechat {
      userPackages.comunicacion = [ pkgs.weechat ];
      myImpermanence.users.${user}.directories = [ ".weechat" ];
    })
    (lib.mkIf config.comunicacion.element {
      userPackages.comunicacion = [ pkgs.element-desktop ];
      myImpermanence.users.${user}.directories = [ ".config/Element" ];
    })
  ]);
}
