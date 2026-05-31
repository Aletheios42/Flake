{ lib, config, ... }:
let
  wipeScript = ''
    mkdir -p /btrfs_tmp
    mount /dev/disk/by-label/root /btrfs_tmp
    if [[ -e /btrfs_tmp/@ ]]; then
      mkdir -p /btrfs_tmp/old_roots
      timestamp=$(date --date="@$(stat -c %y /btrfs_tmp/@)" "+%Y-%m-%d_%H:%M:%S")
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
    umount /btrfs_tmp
  '';
in
{
  options.impermanencia = {
    enable = lib.mkEnableOption "Activa impermanencia con btrfs root wipe";
    dispositivo = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-partlabel/disk-main-root"; # Nombre que da Disko por defecto
      description = "Ruta al dispositivo btrfs físico";
    };
  };
  config = lib.mkIf config.impermanencia.enable {
    
    # 1. Soporte para el initrd clásico basado en scripts
    boot.initrd.postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) (lib.mkAfter wipeScript);

    # 2. Soporte para el nuevo initrd basado en systemd
    boot.initrd.systemd.services.wipe-btrfs-root = lib.mkIf config.boot.initrd.systemd.enable {
      description = "Wipe BTRFS root subvolume for impermanence";
      wantedBy = [ "initrd.target" ];
      after = [ "initrd-root-device.target" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeScript;
    };

    fileSystems."/persist" = {
      device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@persist" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/ssh"
        "/etc/nixos"
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/postgresql"
        "/var/lib/acme"
        "/var/lib/private"
      ] 
      ++ lib.optional (config.nextcloud.enable or false) "/var/lib/nextcloud"
      ++ lib.optional (config.forgejo.enable or false) "/var/lib/forgejo"
      ++ lib.optional (config.syncthing.enable or false) "/var/lib/syncthing"
      ++ lib.optional (config.vpn.enable or false) "/var/lib/headscale"
      ++ lib.optional (config.media.musica.enable or false) "/var/lib/jellyfin"
      ++ lib.optional (config.media.galeria.enable or false) "/var/lib/immich"
      ++ lib.optional (config.monitoring.enable or false) "/var/lib/openobserve"
      ++ lib.optional (config.passwords.vaultwarden.enable or false) "/var/lib/vaultwarden"
      ++ lib.optional (config.zitadel.enable or false) "/var/lib/zitadel"
      ++ lib.optional (config.firefly.enable or false) "/var/lib/firefly-iii";

      users.aletheios42 = {
        directories = [
          "Multimedia"
          "Documentos"
          "Descargas"
          "Imágenes"
          "sync"
          ".config"
          ".local/share"
          ".ssh"
        ];
      };

      files = [
        "/etc/machine-id"
      ];
    };
  };
}
