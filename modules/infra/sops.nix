{ lib, config, ... }:
{
  options.mi_sops = {
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

  config = lib.mkIf config.mi_sops.enable {
    sops = {
      defaultSopsFile = config.mi_sops.secretsFile;
      age = lib.mkMerge [
        (lib.mkIf config.mi_sops.useSshKey {
          # Usar ruta directa al persist para evitar race conditions con bind mounts
          # durante nixos-rebuild switch (los units de impermanence se reciclan brevemente)
          sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
        })
        (lib.mkIf (!config.mi_sops.useSshKey) {
          keyFile = "/var/lib/sops-nix/key.txt";
          generateKey = false;
        })
      ];
      gnupg.sshKeyPaths = [];
    };

    myImpermanence.system.directories =
      lib.optional (!config.mi_sops.useSshKey) "/var/lib/sops-nix";

    # Persistir la clave age del administrador para poder editar/re-encriptar secrets
    myImpermanence.users.${config.vars.usuarioPrincipal}.directories = [ ".config/sops" ];
  };
}
