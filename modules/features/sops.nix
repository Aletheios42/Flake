{ lib, config, ... }:
{
  options.mi_sops = {
    enable = lib.mkEnableOption "Activa Sops-Nix con cifrado age";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "Archivo base de secretos Sops";
    };
  };

  config = lib.mkIf config.mi_sops.enable {
    sops = {
      defaultSopsFile = config.mi_sops.secretsFile;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      gnupg.sshKeyPaths = [];
    };
  };
}
