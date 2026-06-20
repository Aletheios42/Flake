{ lib, config, ... }:
{
  options.oauth2proxy = {
    enable = lib.mkEnableOption "Activa oauth2-proxy para proteger servicios no OIDC";
  };

  config = lib.mkIf config.oauth2proxy.enable {
    assertions = [{
      assertion = config.mi_sops.enable;
      message = "oauth2proxy requiere sops (mi_sops.enable)";
    }];

    sops.secrets."oauth2proxy/env"           = {};
    sops.secrets."oauth2proxy/client_secret" = {};
    sops.secrets."oauth2proxy/cookie_secret" = {};

    services.oauth2-proxy = {
      enable            = true;
      httpAddress       = "http://127.0.0.1:4180";
      provider          = "oidc";
      clientID          = "from-env";
      clientSecretFile  = config.sops.secrets."oauth2proxy/client_secret".path;
      cookie.secretFile = config.sops.secrets."oauth2proxy/cookie_secret".path;
      email.domains     = [ config.vars.dominio ];
      extraConfig = {
        oidc_issuer_url                      = "https://auth.${config.vars.dominio}";
        insecure_oidc_allow_unverified_email = true;
        provider_display_name                = "Zitadel";
      };
    };

    systemd.services.oauth2-proxy = {
      after = [ "zitadel.service" "sops-nix.service" ];
      # clientID y otros ajustes vienen del EnvironmentFile
      serviceConfig.EnvironmentFile = config.sops.secrets."oauth2proxy/env".path;
    };
  };
}
