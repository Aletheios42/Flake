{ lib, config, ... }:
{
  options.rss = {
    enable = lib.mkEnableOption "Activa Miniflux (lector RSS minimalista)";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio para acceder a Miniflux";
    };
  };
  config = lib.mkIf config.rss.enable {
    assertions = [
      {
        assertion = config.vars.dominio != "" && config.rss.subdominio != "";
        message = "Dominio y subdominio son necesarios para Miniflux";
      }
      {
        assertion = config.mi_sops.enable;
        message = "miniflux requiere sops (mi_sops.enable)";
      }
    ];
    sops.secrets."miniflux/admin_credentials" = {};

    mi_postgres.enable = true;
    services.miniflux = {
      enable = true;
      createDatabaseLocally = true;
      adminCredentialsFile = config.sops.secrets."miniflux/admin_credentials".path;
    };
    services.nginx.virtualHosts."${config.rss.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };

    myImpermanence.system.directories = [ "/var/lib/miniflux" ];
  };
}
