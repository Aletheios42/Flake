{ lib, config, ... }:
{
  options.wasteBin = {
    enable = lib.mkEnableOption "Activa WasteBin (pastebin minimalista en Rust)";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Subdominio para acceder a WasteBin";
    };
    port = lib.mkOption { type = lib.types.port; };
  };

  config = lib.mkIf config.wasteBin.enable {
    assertions = [{
      assertion = config.network.dominio != "" && config.wasteBin.subdominio != "";
      message = "WasteBin: Dominio y subdominio son necesarios";
    }];
    
    services.wastebin = {
      enable = true;
      environment = {
      };
    };

    services.nginx.virtualHosts."${config.wasteBin.subdominio}.${config.network.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.wasteBin.port}";
        proxyWebsockets = true;
      };
    };

    environment.persistence."/persist".directories =
      lib.mkIf config.impermanencia.enable [
        { directory = "/var/lib/wastebin"; user = "wastebin"; group = "wastebin"; mode = "0750"; }
      ];
  };
}
