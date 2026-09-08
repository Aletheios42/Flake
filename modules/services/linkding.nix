{pkgs, lib, config, ...}:
{
  options.linkding = {
    enable = lib.mkEnableOption "Activa linkding una app de marcadores";
    puerto = lib.mkOption { type = lib.types.port; };
    subdominio = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf (config.linkding.enable) {
    assertions = [
      {
        assertion = !config._postgres.enable;
        message = "linkding: necesita una base de datos";
      }
      {
        assertion = config.red.dominio != "" && config.miniflux.subdominio != "";
        message = "linkding: Dominio y subdominio son necesarios";
      }
      {
        assertion = config.sops.enable;
        message = "linkding: requiere sops (sops.enable)";
      }
    ];
    sops.secrets."linkding/admin_credentials" = {};
    servives.linkding = {
      enable = true;
      package = [ pkgs.linkding ];
      port = config.linkding.puerto;
      address = "localhost:${toString config.linkding.port}";
      database.port = config._postgres.puerto;
      settings = {
        LD_DISABLE_BACKGROUND_TASKS = "True";
        LD_DISABLE_URL_VALIDATION = "True";
        LD_ENABLE_OIDC = "True";
      };
      environmentFile = config.sops.secrets."linkding/admin_credential".path;
    };

    services.nginx.virtualHosts."${config.linkding.subdominio}.${config.red.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.linkding.puerto}";
        proxyWebsockets = true;
      };
    };

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = config.services.linkding.dataDir; mode = "0750"; }];
    };
  };
}
