{ lib, config, ... }:
{
  options.oauth2proxy = {
    enable = lib.mkEnableOption "Activa oauth2-proxy para proteger servicios no OIDC";
  };

  config = lib.mkIf config.oauth2proxy.enable {
    sops.secrets."oauth2proxy/cookie_secret" = {};
    sops.secrets."oauth2proxy/client_secret" = {};
    sops.secrets."oauth2proxy/client_id"     = {};

    services.oauth2-proxy = {
      enable              = true;
      httpAddress         = "http://127.0.0.1:4180";
      provider            = "oidc";
      cookie.secretFile   = config.sops.secrets."oauth2proxy/cookie_secret".path;
      clientSecretFile    = config.sops.secrets."oauth2proxy/client_secret".path;
      clientID            = "placeholder";
      email.domains       = [ config.vars.dominio ];
      extraConfig = {
        oidc_issuer_url                      = "https://auth.${config.vars.dominio}";
        insecure_oidc_allow_unverified_email = true;
        provider_display_name                = "Zitadel";
      };
    };

    systemd.services.oauth2-proxy = {
      after = [ "zitadel.service" "sops-nix.service" ];
      serviceConfig.EnvironmentFile =
        config.sops.secrets."oauth2proxy/client_id".path;
    };
  };
}
