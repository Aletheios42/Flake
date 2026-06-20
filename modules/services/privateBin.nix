{ lib, config, ... }:
{
  options.privateBin = {
    enable = lib.mkEnableOption "Activa PrivateBin (pastebin privado)";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "subdominio para acceder a PrivateBin";
    };
  };
  config = lib.mkIf config.privateBin.enable {
    assertions = [{
      assertion = config.vars.dominio != "" && config.privateBin.subdominio != "";
      message = "Dominio y subdominio son necesarios para PrivateBin";
    }];
    services.privatebin = {
      enable = true;
      enableNginx = true;
      virtualHost = "${config.privateBin.subdominio}.${config.vars.dominio}";
      settings = {
        main = {
          name = "PrivateBin - ${config.vars.dominio}";
          discussion = true;
          qrcode = true;
        };
      };
    };
    services.nginx.virtualHosts."${config.privateBin.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
    };

    myImpermanence.system.directories = [ "/var/lib/privatebin" ];
  };
}
