{ lib, config, ... }:
{
  options.media.musica = {
    enable = lib.mkEnableOption "Activa jellyfin";
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "usuario del dominio";
    };
  };

  config = lib.mkIf config.media.musica.enable {
    assertions = [{
      assertion = config.network.dominio != "" && config.media.musica.subdominio != "";
      message = "Dominio y Subdominio son necesarios";
    }];
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
    services.nginx.virtualHosts."${config.media.musica.subdominio}.${config.network.dominio}" = {
      forceSSL = true;
      useACMEHost = "wildcard";
      locations."/" = {
        proxyPass = "http://localhost:8096";
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

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "/var/lib/jellyfin" ; mode = "0750"; }];
    };
  };
}
