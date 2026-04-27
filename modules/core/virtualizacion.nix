{ lib, config, ...}:
{
  options.virtualizacion = {
    enable = lib.mkEnableOption "activa el modulo de virtualizacion y contenedores";
    docker = lib.mkEnableOption "activa Docker";
    podman = lib.mkEnableOption "activa Podman";
    libvirtd = lib.mkEnableOption "activa libvirt";
  };

  config = lib.mkIf (config.virtualizacion.enable) (lib.mkMerge [
    (lib.mkIf (config.virtualizacion.docker) {
      virtualizacion.docker = {
        enable = true;
        daemon-settings = { "exec-opts" = [ "native.cgroupdriver=systemd" ]; };
      };
    })
    (lib.mkIf (config.virtualizacion.podman) {
      virtualizacion.podman.enable = true;
    })
    (lib.mkIf (config.virtualizacion.libvirtd) {
      virtualizacion.libvirtd.enable = true;
    })
  ]);
}
