{...}:
{
  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        "exec-opts" = ["native.cgroupdriver=systemd"];
      };
    };
    podman.enable = true;
    libvirtd.enable = true;
  };
}
