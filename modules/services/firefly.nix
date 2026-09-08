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
        assertion = config.network.dominio != "" && config.firefly.subdominio != "" && config.firefly.usuario != "";
        message = "Dominio, subdominio y usuario deben estar especificados.";
      }
      {
        assertion = config.sops.enable;
        message = "firefly requiere sops (sops.enable)";
      }
    ];
    sops.secrets."firefly/app_key" = {};

    postgres.enable = true;

    services.postgresql = {
      ensureDatabases = [ "firefly-iii" ];
      ensureUsers = [{
        name = "firefly-iii";
        ensureDBOwnership = true;
      }];
    };

    services.firefly-iii = {
      enable = true;
      virtualHost = "${config.firefly.subdominio}.${config.network.dominio}";
      enableNginx = true;
      settings = {
        APP_ENV = "production";
        APP_KEY_FILE = config.sops.secrets."firefly/app_key".path;
        SITE_OWNER = "admin@${config.network.dominio}";
        DB_CONNECTION = "pgsql";
        DB_HOST = "/run/postgresql";
        DB_DATABASE = "firefly-iii";
        DB_USERNAME = "firefly-iii";
      };
    };

    # Asegurar que firefly-iii espera a que SOPS descifre los secrets
    # Nota: en versiones recientes de sops-nix, los secrets se descifran como
    # activation script (no como servicio systemd). Usamos wants/after para que
    # la dependencia sea opcional y no rompa si sops-nix.service no existe.
    systemd.services.firefly-iii-setup = {
      after = [ "sops-nix.service" ];
      wants = [ "sops-nix.service" ];
    };

    services.nginx.virtualHosts."${config.firefly.subdominio}.${config.network.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
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

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "/var/lib/firefly-iii" ; mode = "0750"; }];
    };
  };
}
