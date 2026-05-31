{ lib, config, ... }:
{
  options.oauth2proxy = {
    enable = lib.mkEnableOption "Activa oauth2-proxy para proteger servicios no OIDC";
  };

  config = lib.mkIf config.oauth2proxy.enable {
    services.oauth2-proxy = {
      enable = true;
      httpAddress = "http://127.0.0.1:4180";
      cookie.secret = config.sops.secrets."oauth2proxy/cookie_secret".path;
      provider = "oidc";
      clientID = config.sops.secrets."oauth2proxy/client_id".path;
      clientSecret = config.sops.secrets."oauth2proxy/client_secret".path;
      email.domains = [ config.vars.dominio ];
      extraConfig = {
        oidc_issuer_url = "https://auth.${config.vars.dominio}";
        insecure_oidc_allow_unverified_email = true;
        provider_display_name = "Zitadel";
      };
    };

    systemd.services.oauth2-proxy.after = [ "zitadel.service" "sops-nix.service" ];
  };
}
