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
          "Infrastructure" = lib.optionals true [
            (lib.optionalAttrs config.zitadel.enable    { Zitadel    = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/zitadel.png";    href = "https://${config.zitadel.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.vpn.enable        { Headscale  = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/headscale.png";   href = "https://${config.vpn.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.mi_mailserver.enable { Mail    = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/email.png";       href = "https://mail.${config.vars.dominio}"; }; })
          ];
        }
        {
          "Apps" = lib.optionals true [
            (lib.optionalAttrs config.nextcloud.enable  { Nextcloud   = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/nextcloud.png";   href = "https://${config.nextcloud.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.forgejo.enable    { Forgejo     = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/forgejo.png";     href = "https://${config.forgejo.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.syncthing.enable  { Syncthing   = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/syncthing.png";   href = "https://${config.syncthing.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.passwords.vaultwarden.enable { Vaultwarden = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/vaultwarden.png"; href = "https://${config.passwords.vaultwarden.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.firefly.enable    { Firefly     = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/firefly-iii.png"; href = "https://${config.firefly.subdominio}.${config.vars.dominio}"; }; })
          ];
        }
        {
          "Media" = lib.optionals true [
            (lib.optionalAttrs config.media.musica.enable { Jellyfin  = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jellyfin.png";    href = "https://${config.media.musica.subdominio}.${config.vars.dominio}"; }; })
            (lib.optionalAttrs config.media.galeria.enable { Immich   = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/immich.png";      href = "https://${config.media.galeria.subdominio}.${config.vars.dominio}"; }; })
          ];
        }
        {
          "Monitoring" = lib.optionals config.monitoring.enable [
            { OpenObserve = { icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/openobserve.png"; href = "https://${config.monitoring.subdominio}.${config.vars.dominio}"; }; }
          ];
        }
      ];
      docker.socket = lib.mkIf config.virtualizacion.docker "/var/run/docker.sock";
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

    myImpermanence.system.directories = [ "/var/lib/homepage-dashboard" ];
  };
}
