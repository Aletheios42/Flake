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
      type = lib.types.listOf lib.types.port;
      default = [80 443 1234];
      description = "Puertos abiertos en el firewall";
    }; 
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Zona horaria";
    }; 
    dominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Construye el fqdn";
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
    ];

    networking = {
      hostName = config.red.hostname;
      nameservers = config.red.servidoresDns;
      domain = config.red.dominio;
      firewall = {
        enable = config.red.firewall;
        allowedTCPPorts = config.red.puertosPermitidos;
        backend = "iptables";
      };
      networkmanager = {
        enable = true;
        dns = "none";
        wifi.powersave = false;
      };
    };
    time.timeZone = config.red.timeZone;

    environment.persistence."/persist" = lib.mkIf config.impermanencia.enable {
      directories = [
        {
          directory = "/etc/NetworkManager/system-connections";
          user = "root";
          group = "root";
          mode = "0700";
        }
        {
          directory = "/var/lib/NetworkManager";
          user = "root";
          group = "root";
          mode = "0700";
        }
      ];
    };
  };
}
