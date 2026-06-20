{ pkgs, lib, config, ...}:
{
  options.virtualizacion = {
    enable = lib.mkEnableOption "activa el modulo de virtualizacion y contenedores";
    docker = lib.mkEnableOption "activa Docker";
    podman = lib.mkEnableOption "activa Podman";
    qemu  = lib.mkEnableOption "activa qemu";
  };
  config = lib.mkIf (config.virtualizacion.enable) (lib.mkMerge [
    (lib.mkIf (config.virtualizacion.docker) {
      virtualisation.docker = {
        enable = true;
        daemon.settings = { "exec-opts" = [ "native.cgroupdriver=systemd" ]; };
      };
    })
    (lib.mkIf (config.virtualizacion.podman) {
      virtualisation.podman.enable = true;
    })
    (lib.mkIf (config.virtualizacion.qemu) {
      virtualisation.libvirtd.enable = true;

      # libvirt 12.4+ necesita un credential de cifrado para sus secretos internos.
      # Si el fichero está vacío o no existe, generarlo automáticamente.
      systemd.services.libvirtd.preStart = lib.mkBefore ''
        keyfile=/var/lib/libvirt/secrets/secrets-encryption-key
        if [ ! -s "$keyfile" ]; then
          mkdir -p /var/lib/libvirt/secrets
          ${pkgs.coreutils}/bin/dd if=/dev/urandom bs=32 count=1 2>/dev/null \
            | ${pkgs.systemd}/bin/systemd-creds encrypt \
                --name=secrets-encryption-key - "$keyfile"
        fi
      '';

      myImpermanence.system.directories = [ "/var/lib/libvirt" ];
    })
  ]);
}
