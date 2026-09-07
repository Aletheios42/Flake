{ pkgs, lib, config, ... }:
{
  options.rbw = {
    enable = lib.mkEnableOption "Activa cliente Bitwarden CLI (rbw)";
    pinentry = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pinentry-curses;
      description = "Paquete pinentry (curses, rofi, gnome, etc.)";
    };
  };

  config = lib.mkIf config.rbw.enable {
    userPackages.seguridad = [
      pkgs.rbw
      pkgs.pinentry-rofi
      pkgs.rofi-rbw-wayland
    ];

    system.activationScripts.rbwConfig = ''
  mkdir -p /home/${config.usuarioPrincipal}/.config/rbw
  cat > /home/${config.usuarioPrincipal}/.config/rbw/config.json <<EOF
  { "pinentry": "${pkgs.pinentry-rofi}/bin/pinentry-rofi", "lock_timeout": 315360000 }
  EOF
  chown ${config.usuarioPrincipal}:users /home/${config.usuarioPrincipal}/.config/rbw/config.json
    '';
    myImpermanence.users.${config.usuarioPrincipal}.directories = [
      ".config/rbw"
      ".cache/rbw"
    ];
  };
}
