{ pkgs, lib, config, ... }:
{
  options.passwords.enable = lib.mkEnableOption "Gestion de mis contaseñas";

  config = lib.mkIf (config.passwords.enable) {
    userPackages.seguridad = [ pkgs.keepassxc ]; 

    environment.etc."xdg/keepassxc/keepassxc.ini".text = ''
    [GUI]
    ApplicationTheme=dark
    '';
  };
}
