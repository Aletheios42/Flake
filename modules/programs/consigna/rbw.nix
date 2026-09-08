{ pkgs, lib, config, ... }:
{
  options.rbw = {
    enable = lib.mkEnableOption "Activa cliente Bitwarden CLI (rbw)";
  };
  config = lib.mkIf config.rbw.enable {
    assertions = [{
        assertion = config.sops.enable != "";
        message = "rbw: necesita sops para cargar base_url y secretos";
      }];
    sops.secrets."rbw/email".key = "rbw_email";
    sops.secrets."rbw/base_url".key = "rbw_base_url";

    userPackages.seguridad = [ pkgs.rbw pkgs.pinentry-rofi pkgs.rofi-rbw-wayland ];
    system.activationScripts.rbwConfig = ''
      mkdir -p /home/${config.usuarioPrincipal}/.config/rbw
      chmod 700 /home/${config.usuarioPrincipal}/.config/rbw
      EMAIL=$(cat ${config.sops.secrets."rbw/email".path})
      BASE_URL=$(cat ${config.sops.secrets."rbw/base_url".path})
      cat > /home/${config.usuarioPrincipal}/.config/rbw/config.json <<EOF
      { "email": "$EMAIL", "base_url": "$BASE_URL", "pinentry": "${pkgs.pinentry-rofi}/bin/pinentry-rofi", "lock_timeout": 315360000 }
      EOF
      chown ${config.usuarioPrincipal}:users /home/${config.usuarioPrincipal}/.config/rbw/config.json
    '';
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".config/rbw"; mode = "0700";}
          { directory = ".cache/rbw"; mode = "0700";}
        ];
      };
  };
}
