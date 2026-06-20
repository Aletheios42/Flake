{ lib, config, ... }: {
  options.forgejo = {
    enable = lib.mkEnableOption "Activa un servidor de forjeo";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio desde el que acceder al servidor";
    };
  };

  config = lib.mkIf (config.forgejo.enable) {
    mi_postgres.enable = true;

    services.forgejo = {
      enable = true;
      database.type = "postgres";
      database.createDatabase = true;
      settings = {
        server = {
          DOMAIN = "${config.forgejo.subdominio}.${config.vars.dominio}";
          ROOT_URL = "https://${config.forgejo.subdominio}.${config.vars.dominio}";
          HTTP_PORT = 3001;
        };
        service.DISABLE_REGISTRATION = true;
        actions.ENABLED = true;
      };
    };

    services.nginx.virtualHosts."${config.forgejo.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3001";
      };
    };

    myImpermanence.system.directories = [ "/var/lib/forgejo" ];
  };
}
