{ lib, config, ... }:
{
  options.nginx = {
    enable = lib.mkEnableOption "Enciende nginx";
    email = lib.mkOption {
      type = lib.types.str;
      description = "El email de recurperacion de acme";
    };
  };

  config = lib.mkIf(config.nginx.enable) {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = config.nginx.email;
    };
  };
}
