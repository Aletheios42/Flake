{ pkgs, lib, config, ... }:
{
  options.navegadores.tor = {
    enable = lib.mkEnableOption "Activa Tor y Tor Browser";
  };

  config = lib.mkIf (config.navegadores.tor.enable) {
    userPackages.navegadores = [
      pkgs.tor
      pkgs.tor-browser
    ];

    environment.persistence."/persist".users.${config.usuarioPrincipal} = 
      lib.mkIf (config.impermanencia.enable) {
        directories = [{ directory = ".local/share/tor-browser"; mode = "0755";}];
      };
  };
}
