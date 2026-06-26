{ lib, config, ...}:
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
      myImpermanence.system.directories = [ "/var/lib/libvirt" "/var/lib/systemd"  ];
    })
  ]);
}
