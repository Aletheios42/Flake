{ lib, config,  ... }:
{
  options.firefly = {
    enable = lib.mkEnableOption "activa firefly";
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "subdominio para acceer a firefly";
    };
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario para ejecutar firefly-iii";
    };
  };

  config = lib.mkIf (config.firefly.enable) {

    services.firefly-iii = {
      enable = true;
      virtualHost = "${config.firefly.subdominio}.${config.vars.dominio}";
      enableNginx = true;
      settings = {
        APP_ENV = "production";
        APP_KEY_FILE = "/var/secrets/firefly-app-key.txt";
        SITE_OWNER = "${config.firefly.usuario}@${config.vars.dominio}";
        DB_CONNECTION = "pgsql";
      };
    };
  };
}
