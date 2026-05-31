{ lib, config, ... }:
{
  options.zitadel = {
    enable = lib.mkEnableOption "Activa Zitadel SSO";
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Subdominio de autenticacion SSO";
    };
  };

  config = lib.mkIf config.zitadel.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "zitadel" ];
      ensureUsers = [{
        name = "zitadel";
        ensureDBOwnership = true;
      }];
    };

    services.zitadel = {
      enable = true;
      masterKeyFile = config.sops.secrets."zitadel/master_key".path;
      settings = {
        Port = 8081;
        ExternalDomain = "${config.zitadel.subdominio}.${config.vars.dominio}";
        ExternalSecure = true;
        ExternalPort = 443;
        # Tell Zitadel to use Postgres instead of its default CockroachDB
        Database = {
          postgres = {
            Host = "/run/postgresql";
            Port = 5432;
            Database = "zitadel";
            User = {
              Username = "zitadel";
              SSL.Mode = "disable";
            };
            # Zitadel requires admin DB credentials to run its setup migrations
            Admin = {
              Username = "postgres";
              SSL.Mode = "disable";
            };
          };
        };
      };
    };

    systemd.services.zitadel.after = [ "sops-nix.service" "postgresql.service" ];

    services.nginx.virtualHosts."${config.zitadel.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8081";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
}
