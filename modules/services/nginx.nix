{ lib, config, pkgs, ... }:
{
  options.nginx = {
    enable = lib.mkEnableOption "Activa nginx como reverse proxy";
    email  = lib.mkOption {
      type        = lib.types.str;
      description = "Email para ACME/Let's Encrypt";
    };
    ssl = {
      enable = lib.mkOption {
        type        = lib.types.bool;
        default     = true;
        description = "Activa SSL/TLS con ACME (Let's Encrypt) por defecto en todos los vhosts";
      };
    };
    proxyManager = {
      enable = lib.mkEnableOption "Activa nginx-proxy-manager (UI web para gestionar proxies y SSL)";
      port   = lib.mkOption {
        type        = lib.types.port;
        default     = 81;
        description = "Puerto de la interfaz web de nginx-proxy-manager";
      };
      dataDir = lib.mkOption {
        type        = lib.types.str;
        default     = "/var/lib/nginx-proxy-manager";
        description = "Directorio de datos de nginx-proxy-manager";
      };
    };
  };

  config = lib.mkIf config.nginx.enable {
    assertions = [
      {
        assertion = config.nginx.email != "";
        message   = "nginx.email no puede estar vacío (se usa para ACME/Let's Encrypt)";
      }
      {
        assertion = !(config.nginx.enable && config.nginx.proxyManager.enable);
        message   = "nginx nativo y nginx-proxy-manager no pueden estar activos a la vez (conflicto en puertos 80/443)";
      }
    ];

    # ── nginx nativo (cuando proxyManager está desactivado) ───────────────
    services.nginx = lib.mkIf (!config.nginx.proxyManager.enable) {
      enable                = true;
      recommendedProxySettings = true;
      recommendedTlsSettings   = lib.mkIf config.nginx.ssl.enable true;
      recommendedGzipSettings  = true;
    };

    security.acme = lib.mkIf (config.nginx.ssl.enable && !config.nginx.proxyManager.enable) {
      acceptTerms     = true;
      defaults.email  = config.nginx.email;
    };

    myImpermanence.system.directories =
      [ "/var/lib/acme" ]
      ++ lib.optional config.nginx.proxyManager.enable config.nginx.proxyManager.dataDir;

    # ── nginx-proxy-manager via contenedor OCI (Docker) ───────────────────
    virtualisation.oci-containers.containers = lib.mkIf config.nginx.proxyManager.enable {
      nginx-proxy-manager = {
        image  = "jc21/nginx-proxy-manager:latest";
        ports  = [
          "80:80"
          "443:443"
          "${toString config.nginx.proxyManager.port}:81"
        ];
        volumes = [
          "${config.nginx.proxyManager.dataDir}:/data"
          "${config.nginx.proxyManager.dataDir}/letsencrypt:/etc/letsencrypt"
        ];
        environment = {
          DISABLE_IPV6 = "true";
        };
        autoStart = true;
      };
    };
  };
}
