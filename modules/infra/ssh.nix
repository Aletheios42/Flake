{ lib, config, ... }:
{
  options.mi_ssh = {
    enable = lib.mkEnableOption "Activa el modulo ssh";
    cliente.enable = lib.mkEnableOption "Activa el cliente ssh";
    servidor = {
      enable = lib.mkEnableOption "Activa el servidor ssh";
      puertos = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        description = "Lista de los puertos que puede usar ssh";
      };
    };
  };

  config = lib.mkIf config.mi_ssh.enable (lib.mkMerge [
    (lib.mkIf config.mi_ssh.cliente.enable {
      programs.ssh = {
        startAgent = true;
        extraConfig = ''
          Host *
            ForwardAgent yes
            AddKeysToAgent yes
        '';
      };
    })
    (lib.mkIf config.mi_ssh.servidor.enable {
      services.openssh = {
        enable = true;
        ports = config.mi_ssh.servidor.puertos;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "prohibit-password";
          ClientAliveInterval = 120;
          ClientAliveCountMax = 3;
        };
        hostKeys = [{
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }];
      };
      networking.firewall.allowedTCPPorts = config.mi_ssh.servidor.puertos;
      myImpermanence.system.directories = [ "/etc/ssh" ];
    })
    {
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".ssh" ];
      };
    }
  ]);
}
