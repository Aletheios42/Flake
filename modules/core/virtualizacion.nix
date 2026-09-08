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
    (lib.mkIf config.virtualizacion.qemu {
      userPackages.virtualizacion = [ pkgs.qemu ];
      virtualisation.libvirtd.enable = true;
      environment.persistence."/persist" = lib.mkIf config.impermanencia.enable {
        directories = [
          { directory = "/var/lib/libvirt/dnsmasq";  user = "root"; group = "root"; mode = "0755"; }
          { directory = "/var/lib/libvirt/hooks";    user = "root"; group = "root"; mode = "0755"; }
          { directory = "/var/lib/libvirt/nwfilter"; user = "root"; group = "root"; mode = "0755"; }
          { directory = "/var/lib/libvirt/qemu";     user = "root"; group = "root"; mode = "0755"; }
        ];
        files = [ "/var/lib/libvirt/network.conf" "/var/lib/libvirt/qemu.conf" ];
      };
    })
  ]);
}
