{ lib, config, ... }:
{
  options.mi_postgres.enable = lib.mkEnableOption "...";

  config = lib.mkIf config.mi_postgres.enable {
    services.postgresql.enable = true;
    myImpermanence.system.directories = [ "/var/lib/postgresql" ];
  };
}
