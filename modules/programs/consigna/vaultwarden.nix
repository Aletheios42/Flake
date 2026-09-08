{ lib, config, ... }:
{
  options.vaultwarden = {
    enable = lib.mkEnableOption "Activa servidor Vaultwarden";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "vaultwarden";
      description = "Subdominio asignado al servidor";
    };
    puerto = lib.mkOption {
      type = lib.types.port;
      default = 8222;
      description = "Puerto local de escucha de Vaultwarden";
    };
  };

  config = lib.mkIf config.vaultwarden.enable {
    assertions = [{
      assertion = config.red.dominio != "";
      message = "vaultwarden requiere que config.network.dominio esté definido";
    }];

    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://${config.vaultwarden.subdominio}.${config.red.dominio}";
        SIGNUPS_ALLOWED = false;
        ROCKET_PORT = config.vaultwarden.puerto;
      };
    };

    services.nginx.virtualHosts."${config.vaultwarden.subdominio}.${config.red.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.vaultwarden.puerto}";
        proxyWebsockets = true;
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

    environment.persistence."/persist" = 
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          {
            directory = "/var/lib/vaultwarden";
            user = "vaultwarden"; group = "vaultwarden"; mode = "0700";
          }
        ];
      };
  };
}
