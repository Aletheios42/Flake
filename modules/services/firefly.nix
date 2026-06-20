{ lib, config, ... }:
{
  options.firefly = {
    enable = lib.mkEnableOption "activa firefly";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio para acceer a firefly";
    };
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario para ejecutar firefly-iii";
    };
  };

  config = lib.mkIf (config.firefly.enable) {
    assertions = [
      {
        assertion = config.vars.dominio != "" && config.firefly.subdominio != "" && config.firefly.usuario != "";
        message = "Dominio, subdominio y usuario deben estar especificados.";
      }
      {
        assertion = config.mi_sops.enable;
        message = "firefly requiere sops (mi_sops.enable)";
      }
    ];
    sops.secrets."firefly/app_key" = {};

    mi_postgres.enable = true;

    services.postgresql = {
      ensureDatabases = [ "firefly-iii" ];
      ensureUsers = [{
        name = "firefly-iii";
        ensureDBOwnership = true;
      }];
    };

    services.firefly-iii = {
      enable = true;
      virtualHost = "${config.firefly.subdominio}.${config.vars.dominio}";
      enableNginx = true;
      settings = {
        APP_ENV = "production";
        APP_KEY_FILE = config.sops.secrets."firefly/app_key".path;
        SITE_OWNER = "admin@${config.vars.dominio}";
        DB_CONNECTION = "pgsql";
        DB_HOST = "/run/postgresql";
        DB_DATABASE = "firefly-iii";
        DB_USERNAME = "firefly-iii";
      };
    };

    services.nginx.virtualHosts."${config.firefly.subdominio}.${config.vars.dominio}" = {
      locations."/" = {
        extraConfig = lib.optionalString config.oauth2proxy.enable ''
          auth_request /oauth2/auth;
          error_page 401 = /oauth2/sign_in;
        '';
      };
      locations."/oauth2/" = lib.mkIf config.oauth2proxy.enable {
        proxyPass = "http://127.0.0.1:4180";
        extraConfig = ''
          proxy_set_header X-Scheme $scheme;
          proxy_set_header X-Auth-Request-Redirect $request_uri;
          proxy_set_header Host $host;
        '';
      };
    };

    myImpermanence.system.directories = [ "/var/lib/firefly-iii" ];
  };
}
