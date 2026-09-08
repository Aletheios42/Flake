{ pkgs, lib, config, ... }:
let
  user = config.usuarioPrincipal;
  thunderbirdPrefs = ''
    user_pref("ui.systemUsesDarkTheme", 1);
    user_pref("browser.theme.content-theme", 0);
    user_pref("browser.theme.toolbar-theme", 0);
    user_pref("extensions.activeThemeID", "thunderbird-compact-dark@mozilla.org");
  '';
in
{
  options.comunicacion.thunderbird = lib.mkEnableOption "Activa thunderbird";

  config = lib.mkIf config.comunicacion.thunderbird {
    userPackages.comunicacion = [ pkgs.thunderbird ];
    system.activationScripts.thunderbird-dark = {
      deps = [ "users" ];
      text = ''
        TB_DIR="/home/${user}/.thunderbird"
        if [ -d "$TB_DIR" ]; then
          PROFILE_PATH=$(${pkgs.gnugrep}/bin/grep -E '^Path=' "$TB_DIR/profiles.ini" 2>/dev/null | head -1 | cut -d= -f2)
          if [ -n "$PROFILE_PATH" ] && [ -d "$TB_DIR/$PROFILE_PATH" ]; then
            USER_JS="$TB_DIR/$PROFILE_PATH/user.js"
            if ! ${pkgs.gnugrep}/bin/grep -q "thunderbird-compact-dark" "$USER_JS" 2>/dev/null; then
              cat >> "$USER_JS" << 'TBEOF' 
        ${thunderbirdPrefs}TBEOF
            fi
          fi
        fi
      '';
    };
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [{ directory = ".thunderbird"; mode = "0700";}];
      };
  };
}
