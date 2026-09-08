{ pkgs, lib, config, ... }:

let
  cfg = config.webs.europaNosUne;
in
{
  options.webs.europaNosUne = {
    enable = lib.mkEnableOption "Despliega el periodico Europa Nos Une";
    gitUrl = lib.mkOption {
      type = lib.types.strMatching "^https?://.+";
      description = "URL git del código fuente";
    };
    puertoDirectus  = lib.mkOption { type = lib.types.port; };
    puertoFrontend  = lib.mkOption { type = lib.types.port; };
    subdominio      = lib.mkOption { type = lib.types.str; };
    WorkingDirectory = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.gitUrl != "";           message = "europa nos une: Ruta obligatoria (URL git) del código fuente"; }
      { assertion = cfg.subdominio != "";        message = "europa nos une: subdominio obligatorio"; }
      { assertion = cfg.WorkingDirectory != "";  message = "europa nos une: necesitas declarar una ruta para los datos"; }
    ];

    networking.firewall.allowedTCPPorts = [
      cfg.puertoDirectus
      cfg.puertoFrontend
    ];

    sops.secrets."nosune/admin_credentials" = {};

    postgres.enable = true;

    systemd.services.nosune-compose = {
      description = "EuropaNosUne";
      after    = [ "network-online.target" "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.git pkgs.docker pkgs.docker-compose ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = cfg.WorkingDirectory;
        ExecStartPre = pkgs.writeShellScript "nosune-fetch" ''
          set -eu
          if [ ! -d "${cfg.WorkingDirectory}/src/.git" ]; then
            ${pkgs.git}/bin/git clone --depth 1 "${cfg.gitUrl}" "${cfg.WorkingDirectory}"
          else
            ${pkgs.git}/bin/git -C "${cfg.WorkingDirectory}/src" pull
          fi
        '';
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${cfg.WorkingDirectory}/src/docker-compose.yml up -d";
        ExecStop  = "${pkgs.docker-compose}/bin/docker-compose -f ${cfg.WorkingDirectory}/src/docker-compose.yml down";
      };
    };

    services.nginx.virtualHosts."${cfg.subdominio}.${config.red.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString cfg.puertoFrontend}";
    };

    services.nginx.virtualHosts."cms.${cfg.subdominio}.${config.red.dominio}" = {
      useACMEHost = "wildcard";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.puertoDirectus}";
        proxyWebsockets = true;
      };
    };
    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "${cfg.WorkingDirectory}" ; mode = "0750"; }];
    };
  };
}
