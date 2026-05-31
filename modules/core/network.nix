{ lib, config, ...}:
{
  options.red = {
    enable = lib.mkEnableOption "";
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "El hostname de la maquina";
    }; 
    servidoresDns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["9.9.9.9" "1.1.1.1"];
      description = "Servidores DNS";
    }; 
    firewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enciende o apaga el firewall";
    };
    puertosPermitidos = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [80 443 1234];
      description = "Puertos abiertos en el firewall";
    }; 
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Zona horaria";
    }; 
  };

  config = lib.mkIf (config.red.enable) {
    assertions = [
      {
        assertion = config.red.hostname != "";
        message = "hostname no puede ser una cadena vacia";
      }
      {
        assertion = config.red.timeZone != "";
        message = "timezone no puede ser una cadena vacia";
      }
      {
        assertion = lib.all (p: p >= 0 && p <= 65535) config.red.puertosPermitidos;
        message = "Los puertos validos estan en el rango 0-65535";
      }
    ];

    networking = {
      hostName = config.red.hostname;
      nameservers = config.red.servidoresDns;
      firewall = {
        enable = config.red.firewall;
        allowedTCPPorts = config.red.puertosPermitidos;
      };
      networkmanager = {
        enable = true;
        dns = "none";
      };
    };
    time.timeZone = config.red.timeZone;
  };
}
