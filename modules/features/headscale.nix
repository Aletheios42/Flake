{ pkgs, lib, config , ... }: {
  options.vpn = {
    enable = lib.mkEnableOption "activa headscale";
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario que ejecuta la app";
    };
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "subdomino con el que acceder a la vpn";
    };
  };

  config = lib.mkIf (config.vpn.enable) {
    services.headscale = {
      enable = true;
      package = pkgs.headscale;
      user = config.vpn.usuario;
      port = 8080;
      address = "127.0.0.1"; # mirar esto
      settings = {
        server_url = "https://${config.vpn.subdominio}.${config.vars.dominio}";
        ip_prefixes = [ "100.64.0.0/10" ];
        database.type = "sqlite3";
        database.sqlite.path = "/var/lib/headscale/db.sqlite";
        dns = {
          nameservers.global = [ "1.1.1.1" ];
          magic_dns = false;  # evita los dos errores de DNS
        };
      };
    };

    services.nginx.virtualHosts."${config.vpn.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };
    };
  };
}
