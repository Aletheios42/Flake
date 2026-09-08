{ lib, config, ... }:
let
  wipeScript = ''
    mkdir -p /btrfs_tmp
    mount ${config.impermanencia.dispositivo} /btrfs_tmp
    if [[ -e /btrfs_tmp/@ ]]; then
      mkdir -p /btrfs_tmp/old_roots
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%d_%H:%M:%S")
      mv /btrfs_tmp/@ "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
      delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/@

    # Asegurar que @persist existe (primer deploy o si alguien lo borro)
    if ! btrfs subvolume show /btrfs_tmp/@persist 2>/dev/null; then
      btrfs subvolume create /btrfs_tmp/@persist
    fi

    umount /btrfs_tmp
  '';
in
{
  options.impermanencia = {
    enable = lib.mkEnableOption "Activa impermanencia con btrfs root wipe";
    dispositivo = lib.mkOption {
      type = lib.types.str;
      description = "Ruta al dispositivo btrfs físico";
    };
  };

  config = lib.mkIf config.impermanencia.enable {
    boot.initrd.postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) (lib.mkAfter wipeScript);

    boot.initrd.systemd.services.wipe-btrfs-root = lib.mkIf config.boot.initrd.systemd.enable {
      description = "Wipe BTRFS root subvolume for impermanence";
      wantedBy = [ "initrd.target" ];
      after = [ "initrd-root-device.target" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeScript;
    };

    fileSystems."/persist".neededForBoot = true;

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        { directory = "/var/lib/nixos"; user = "root"; group = "root"; mode = "0755"; }
        { directory = "/var/log"; user = "root"; group = "root"; mode = "0755"; }
      ];
      files = [
        { file = "/etc/machine-id"; }
      ];
    };

    system.activationScripts.impermanenceBootstrap = {
      deps = [];
      text = ''
    # Copiar SSH keys existentes a /persist (primer deploy con impermanence)
    if [ ! -f /persist/etc/ssh/ssh_host_ed25519_key ] && [ -f /etc/ssh/ssh_host_ed25519_key ]; then
      mkdir -p /persist/etc/ssh
      cp /etc/ssh/ssh_host_* /persist/etc/ssh/
    fi
    # Copiar machine-id existente a /persist (primer deploy)
    if [ ! -f /persist/etc/machine-id ] && [ -f /etc/machine-id ]; then
      cp /etc/machine-id /persist/etc/machine-id
    fi
      '';
    };
  };
}
