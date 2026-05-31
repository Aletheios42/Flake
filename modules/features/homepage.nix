{ lib, config, ... }:
{
  options.homepage = {
    enable = lib.mkEnableOption "Activa Homepage Dashboard";
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "Subdominio de dashboard";
    };
  };

  config = lib.mkIf config.homepage.enable {
    services.homepage-dashboard = {
      enable = true;
      services = [
        {
          "Infrastructure" = [
            { Zitadel = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/zitadel.png"; href = "https://auth.${config.vars.dominio}"; }; }
            { Headscale = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/headscale.png"; href = "https://vpn.${config.vars.dominio}"; }; }
            { Mail = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/email.png"; href = "https://mail.${config.vars.dominio}"; }; }
          ];
        }
        {
          "Apps" = [
            { Nextcloud = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/nextcloud.png"; href = "https://cloud.${config.vars.dominio}"; }; }
            { Forgejo = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/forgejo.png"; href = "https://git.${config.vars.dominio}"; }; }
            { Syncthing = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/syncthing.png"; href = "https://syncthing.${config.vars.dominio}"; }; }
            { Vaultwarden = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/vaultwarden.png"; href = "https://vaultwarden.${config.vars.dominio}"; }; }
            { Firefly = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/firefly-iii.png"; href = "https://presupuesto.${config.vars.dominio}"; }; }
          ];
        }
        {
          "Media" = [
            { Jellyfin = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jellyfin.png"; href = "https://jellyfin.${config.vars.dominio}"; }; }
            { Immich = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/immich.png"; href = "https://fotos.${config.vars.dominio}"; }; }
          ];
        }
        {
          "Monitoring" = [
            { OpenObserve = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/openobserve.png"; href = "https://observe.${config.vars.dominio}"; }; }
          ];
        }
      ];
      docker.socket = "/var/run/docker.sock";
    };

    services.nginx.virtualHosts."${config.homepage.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8082";
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
  };
}
