{ pkgs, lib, config,  ... }: {

  options.nextcloud = {
    enable = lib.mkEnableOption "Activa nextcloud";
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario que se va a encargar de nextcloud";
    };
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio para acceder al servidor de nextcloud";
    };
  };

  config = lib.mkIf (config.nextcloud.enable) {
    assertions = [{
      assertion = config.vars.dominio != "" && config.nextcloud.subdominio != "" && config.nextcloud.usuario != "";
      message = "necesitas un dominio, subdominio y usuario para nextlcoud";
    }
    {
      assertion = config.mi_sops.enable;
      message = "nextcloud requiere sops (mi_sops.enable)";
    }];

    sops.secrets."nextcloud/admin_pass" = {};

    mi_postgres.enable = true;

    services.nextcloud = {
      enable = true;
      hostName = "${config.nextcloud.subdominio}.${config.vars.dominio}";
      https = true;
      package = pkgs.nextcloud33;
      config = {
        adminpassFile = config.sops.secrets."nextcloud/admin_pass".path;
        adminuser = "${config.nextcloud.usuario}";
        dbtype = "pgsql";
      };
      database.createLocally = true;
    };

    services.nginx.virtualHosts."${config.nextcloud.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
    };

    myImpermanence.system.directories = [ "/var/lib/nextcloud" ];
  };
}
