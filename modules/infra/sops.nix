{ pkgs, lib, config, ... }:
{
  options.sops = {
    enable = lib.mkEnableOption "Activa Sops-Nix con cifrado age";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "Archivo base de secretos Sops";
    };
    # Cuando true, deriva la clave age de la clave SSH del host (/etc/ssh/ssh_host_ed25519_key).
    # La clave SSH persiste en impermanencia, así que siempre está disponible en el momento
    # en que la activación de sops corre. Evita el problema de "key file not found" en
    # rebuilds donde el bind mount de /var/lib/sops-nix aún no esta activo.
    useSshKey = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Activar para derivar la clave age de la clave SSH del host en lugar de un key file separado";
    };
  };

  config = lib.mkIf config.sops.enable {
    userPackages.secretos = [ pkgs.sops pkgs.age ];
    sops = {
      defaultSopsFile = config.sops.secretsFile;
      age = lib.mkMerge [
        (lib.mkIf config.sops.useSshKey {
          sshKeyPaths = [
            "/persist/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key"
          ];
        })
        (lib.mkIf (!config.sops.useSshKey) {
          keyFile = "/var/lib/sops-nix/key.txt";
          generateKey = false;
        })
      ];
      gnupg.sshKeyPaths = [];
    };

    environment.persistence."/persist" = lib.mkIf config.impermanencia.enable {
      directories = lib.optional (!config.sops.useSshKey) {
        directory = "/var/lib/sops-nix";
        user = "root";
        group = "root";
        mode = "0700";
      };
      users.${config.usuarioPrincipal}.directories = [
        { directory = ".config/sops"; mode = "0700"; }
      ];
    };
  };
}
