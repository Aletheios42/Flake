{ pkgs, lib, config, ... }: 
{
  options.monitoring = {
    enable = lib.mkEnableOption "Activa OpenObserve";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Subdominio para OpenObserve";
    };
    port = lib.mkOption { type = lib.types.port; };
  };

  config = lib.mkIf config.monitoring.enable {
    assertions = [
      {
        assertion = config.sops.enable;
        message = "monitoring requiere sops (sops.enable)";
      }
      {
        assertion = config.monitoring.subdominio != "";
        message = "monitoring.subdominio no puede estar vacío";
      }
    ];
    sops.secrets."openobserve/root_password" = {};
    sops.secrets."openobserve/secret_key" = {};
    sops.secrets."openobserve/root_password".owner = "openobserve";
    sops.secrets."openobserve/secret_key".owner = "openobserve";

    users.users.openobserve = {
      isSystemUser = true;
      group = "openobserve";
      home = "/var/lib/openobserve";
      createHome = true;
    };
    users.groups.openobserve = {};

    systemd.services.openobserve = {
      description = "OpenObserve monitoring server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "sops-nix.service" ];

      serviceConfig = {
        User = "openobserve";
        Group = "openobserve";
        StateDirectory = "openobserve";
        StateDirectoryMode = "0750";
        ExecStart = pkgs.writeShellScript "openobserve-wrapper" ''
          export ZO_ROOT_USER_PASSWORD=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."openobserve/root_password".path})
          export ZO_ROOT_USER_SECRET_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."openobserve/secret_key".path})
          exec ${pkgs.openobserve}/bin/openobserve
        '';
        WorkingDirectory = "/var/lib/openobserve";
      };

      environment = {
        ZO_ROOT_USER_EMAIL = "admin@${config.network.dominio}";
        ZO_HTTP_PORT = toString config.monitoring.port;
        ZO_DATA_DIR = "/var/lib/openobserve/data";
      };
    };

    services.nginx.virtualHosts."${config.monitoring.subdominio}.${config.network.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.monitoring.port}";
        proxyWebsockets = true;
      };
    };


    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{directory = "/var/lib/openobserve"; mode = "0750";}];
    };

  };
}
