{ lib, config, ... }:
{
  options.postgres.enable = lib.mkEnableOption "Módulo de PostgreSQL y herramientas";
  options.postgres.puerto = lib.mkOption { type = lib.types.port; };
  options.postgres.subdominio = lib.mkOption { type = lib.types.str; };
  options.postgres.pgadmin.puerto = lib.mkOption { type = lib.types.port; };
  options.postgres.datalocation = lib.mkOption { type = lib.types.str; };
  options.postgres.pgbouncer.puerto = lib.mkOption { type = lib.types.port; };
  options.postgres.databases = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Bases de datos a crear automáticamente.";
  };
  config = lib.mkIf config.postgres.enable {
    assertions = [
      {
        assertion = config.red.dominio != "" && config.postgres.subdominio != "";
        message = "Postgres: Dominio y subdominio son necesarios";
      }
    ];
    sops.secrets."pgadmin_password" = {
      owner = "pgadmin"; 
      group = "pgadmin"; 
    };
    services = {
      postgresql = {
        enable = true;
        settings.port = config.postgres.puerto; 
        ensureDatabases = config.postgres.databases;
        ensureUsers = map (db: { 
          name = db; ensureDBOwnership = true;}) config.postgres.databases;
        authentication = lib.mkOverride 10 ''
        local all all trust
        '';
      };
      postgresqlBackup = {
        enable = true;
        location = config.postgres.datalocation;
        backupAll = true;
      };
      pgadmin = {
        enable = true;
        initialEmail = "${config.postgres.subdominio}@${config.networking.domain}";
        initialPasswordFile = config.sops.secrets."pgadmin_password".path;
        port = config.postgres.pgadmin.puerto;
      };
      pgbouncer = {
        enable = true;
        settings = {
          pgbouncer = {
            listen_addr = "127.0.0.1";
            listen_port = config.postgres.pgbouncer.puerto;
            auth_type = "trust";
            auth_file = "/etc/pgbouncer/userlist.txt";
            pool_mode = "transaction";
            max_client_conn = 100;
            default_pool_size = 20;
          };
          databases = {
            "*" = "host=/run/postgresql port=${toString config.postgres.puerto}";
          };
        };
      };
    };
    environment.etc."pgbouncer/userlist.txt".text =
      lib.concatMapStringsSep "\n" (db: ''"${db}" ""'') config.postgres.databases;

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "/var/backup/postgres"; user = "postgres"; group = "postgres"; mode = "0750";}];
    };
  };
}
