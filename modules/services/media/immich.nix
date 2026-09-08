{ lib, config, ... }:
{
  options.media.galeria = {
    enable = lib.mkEnableOption "activa immich";
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "subdominio para acceder a immich";
    };
  };

  config = lib.mkIf config.media.galeria.enable {
    services.immich = {
      enable = true;
      port = 2283;
      mediaLocation = "/var/lib/immich/media";
      database.enable = true;
    };
    services.nginx.virtualHosts."${config.media.galeria.subdominio}.${config.network.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:2283";
        proxyWebsockets = true;
      };
    };

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "/var/lib/immich" ; mode = "0750"; }];
    };
  };
}
