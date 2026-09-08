{ lib, config, ... }:
{
  options.privateBin = {
    enable = lib.mkEnableOption "Activa PrivateBin (pastebin privado)";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio para acceder a PrivateBin";
    };
  };
  config = lib.mkIf config.privateBin.enable {
    assertions = [{
      assertion = config.network.dominio != "" && config.privateBin.subdominio != "";
      message = "Dominio y subdominio son necesarios para PrivateBin";
    }];
    services.privatebin = {
      enable = true;
      enableNginx = true;
      virtualHost = "${config.privateBin.subdominio}.${config.network.dominio}";
      settings = {
        main = {
          name = "PrivateBin - ${config.network.dominio}";
          discussion = true;
          qrcode = true;
        };
      };
    };
    services.nginx.virtualHosts."${config.privateBin.subdominio}.${config.network.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
    };

    environment.persistence."/persist".directories =
      lib.mkIf config.impermanencia.enable [
        { directory = "/var/lib/privatebin"; user = "privatebin"; group = "privatebin"; mode = "0750"; }
      ];
  };
}
