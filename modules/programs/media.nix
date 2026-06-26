{pkgs, lib, config, ...}:
{
  options.media = {
    enable = lib.mkEnableOption "Activa grayjay musikcube pavucontrol vlc mpv ffmpef";
    obs.enable = lib.mkEnableOption "Activa obs proximamente con sus scripts";
    cliente = lib.mkEnableOption "descarga paquetes para multimedia";
    musica = {
      enable = lib.mkEnableOption "Activa jellifin";
      subdominio = lib.mkOption {
        type = lib.types.str;
        description = "usuario del dominio";
      };
    };
    galeria = {
      enable = lib.mkEnableOption "activa immich";
      subdominio = lib.mkOption {
        type = lib.types.str;
        description = "subdominio para acceder a immich";
      };
    };
  };

  config = lib.mkIf (config.media.enable) (lib.mkMerge [
    {
      assertions = [{
        assertion = config.media.cliente || config.media.musica.enable || config.media.galeria.enable ;
        message = "Activa immich , jellyfin o paquetes de cliente";
      }];
    }
    (lib.mkIf (config.media.cliente) {
      userPackages.media = [
        pkgs.grayjay pkgs.musikcube pkgs.pavucontrol pkgs.vlc pkgs.mpv pkgs.ffmpeg
      ];
    })
    (lib.mkIf (config.media.musica.enable) {
      assertions = [{
        assertion = config.vars.dominio != "" && config.media.musica.subdominio != "";
        message = "Dominio y Subdominio son necesarios";
      }];
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };
      services.nginx.virtualHosts."${config.media.musica.subdominio}.${config.vars.dominio}" = {
        forceSSL = true;
        enableACME = true;
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

      myImpermanence.system.directories = [ "/var/lib/jellyfin" ];
    })
    (lib.mkIf (config.media.galeria.enable) {
      services.immich = {
        enable = true;
        port = 2283;
        mediaLocation = "/var/lib/immich/media";
        database.enable = true;
      };

      services.nginx.virtualHosts."${config.media.galeria.subdominio}.${config.vars.dominio}" = {
        enableACME = true; forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
        };
      };

      myImpermanence.system.directories = [ "/var/lib/immich" ];
    })
    (lib.mkIf (config.media.obs.enable)  {
      userPackages.obs = [
        (pkgs.wrapOBS {
          plugins = with pkgs.obs-studio-plugins; [
            wlrobs obs-vkcapture input-overlay
          ];
        })
      ];
    })
  ]);
}
