{ lib, config, ... }:
{
  options.nginx = {
    enable = lib.mkEnableOption "Activa nginx como reverse proxy";
    email  = lib.mkOption {
      type        = lib.types.str;
      description = "Email para ACME/Let's Encrypt";
    };
  };

  config = lib.mkIf config.nginx.enable {
    assertions = [
      {
        assertion = config.nginx.email != "";
        message   = "nginx: email no puede estar vacío (se usa para ACME/Let's Encrypt)";
      }
    ];

    services.nginx = {
      enable                = true;
      recommendedProxySettings = true;
      recommendedTlsSettings   = true;
      recommendedGzipSettings  = true;
    };

    sops.secrets."cloudflare/api_token" = {};
    sops.templates."acme-cloudflare-env" = {
      owner = "acme";
      group = "acme";
      content = ''
        CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare/api_token"}
      '';
    };

    # nginx debe poder leer los certificados ACME (grupo "acme")
    users.users.nginx.extraGroups = [ "acme" ];

    security.acme = {
      acceptTerms     = true;
      defaults.email  = config.nginx.email;
      certs."wildcard" = {
        domain = "*.${config.red.dominio}";
        extraDomainNames = [ "${config.red.dominio}" ];
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."acme-cloudflare-env".path;
      };
    };

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "/var/lib/acme"; user = "acme"; group = "acme"; mode = "0750"; }];
    };
  };
}
