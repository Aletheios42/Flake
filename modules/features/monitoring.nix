{ pkgs, lib, config, ... }: 
{
  options.monitoring = {
    enable = lib.mkEnableOption "Activa OpenObserve";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Subdominio para OpenObserve";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 5080;
      description = "Puerto interno de OpenObserve";
    };
  };

  config = lib.mkIf config.monitoring.enable {
    sops.secrets."openobserve/root_password" = {};
    sops.secrets."openobserve/secret_key" = {};

    users.users.openobserve = {
      isSystemUser = true;
      group = "openobserve";
      home = "/var/lib/openobserve";
      createHome = true;
    };
    users.groups.openobserve = {};

    sops.secrets."openobserve/root_password".owner = "openobserve";
    sops.secrets."openobserve/secret_key".owner = "openobserve";

    systemd.services.openobserve = {
      description = "OpenObserve monitoring server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "sops-nix.service" ];
      
      serviceConfig = {
        User = "openobserve";
        Group = "openobserve";
        ExecStart = "${pkgs.openobserve}/bin/openobserve";
        WorkingDirectory = "/var/lib/openobserve";
        EnvironmentFile = [
          config.sops.secrets."openobserve/root_password".path
          config.sops.secrets."openobserve/secret_key".path
        ];
      };
      
      environment = {
        ZO_ROOT_USER_EMAIL = "admin@${config.vars.dominio}";
        ZO_HTTP_PORT = toString config.monitoring.port;
        ZO_DATA_DIR = "/var/lib/openobserve/data";
      };
    };

    services.nginx.virtualHosts."${config.monitoring.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.monitoring.port}";
        proxyWebsockets = true;
      };
    };
  };
}
