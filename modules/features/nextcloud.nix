{ pkgs, lib, config,  ... }: {

  options.nextcloud = {
    enable = lib.mkEnableOption "Activa nextcloud";
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario que se va a encargar de nextcloud";
    };
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "subdominio para acceder al servidor de nextcloud";
    };
  };


  config = lib.mkIf (config.nextcloud.enable) {
    assertions = [{
      assertion = config.vars.dominio != "" && config.nextcloud.subdominio != "" && config.nextcloud.usuario != ""; ## reundante la comprobacion del subdominoi pero bueno
      message = "necesitas un dominio, subdominio y usuario para nextlcoud";
    }];
    services.nextcloud = {
      enable = true;
      hostName = "${config.nextcloud.subdominio}.${config.vars.dominio}";
      https = true;
      package = pkgs.nextcloud33;
      config = {
        adminpassFile = toString (pkgs.writeText "nextcloud-admin-pass" "password-temporal");
        adminuser = "${config.nextcloud.usuario}";
        dbtype = "pgsql";
      };
      database.createLocally = true;
    };

    services.nginx.virtualHosts."${config.nextcloud.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
    };
  };
}
