{ lib, config, ... }:
{
  options.miniflux = {
    enable = lib.mkEnableOption "Activa Miniflux (lector RSS minimalista)";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio para acceder a Miniflux";
    };
    puerto = lib.mkOption { type = lib.types.port; };
  };
  config = lib.mkIf config.miniflux.enable {
    assertions = [
      {
        assertion = config.red.dominio != "" && config.miniflux.subdominio != "";
        message = "Miniflux: Dominio y subdominio son necesarios";
      }
      {
        assertion = config.sops.enable;
        message = "Miniflux: requiere sops (sops.enable)";
      }
      {
        assertion = config.postgres.enable;
        message = "miniflux: requiere de postgres";
      }
    ];
    sops.secrets."miniflux/admin_credentials" = {};
    sops.secrets."miniflux/database_url" = {};
    postgres.databases = [ "miniflux" ];
    services.miniflux = {
      enable = true;
      createDatabaseLocally = false;
      adminCredentialsFile = config.sops.secrets."miniflux/admin_credentials".path;
      config = {
        DATABASE_URL_FILE = "%d/database_url";
      };
    };
    systemd.services.miniflux.serviceConfig.LoadCredential =
      "database_url:${config.sops.secrets."miniflux/database_url".path}";
    services.nginx.virtualHosts."${config.miniflux.subdominio}.${config.red.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.miniflux.puerto}";
        proxyWebsockets = true;
      };
    };

    environment.persistence."/persist" = lib.mkIf config.impermanencia.enable {
      directories = [
        { directory = "/var/lib/miniflux"; user = "miniflux"; group = "miniflux"; mode = "0700"; }
      ];
    };
  };
}
