{ lib, config, ...}:
{
  options.arranque = {
    enable = lib.mkEnableOption "Opciones de arranque";
    loader = lib.mkOption {
      type = lib.types.enum [ "dual-boot" "monolito"];
      default = "monolito";
      description = "
      Opciones:
      monolito: Se activa systemd-boot
      dualboot: Se activa grub,
        ";
    };
  };

  config = lib.mkIf (config.arranque.enable) (lib.mkMerge [
    {
      boot.loader.efi.efiSysMountPoint = "/boot";
    }
    (lib.mkIf (config.arranque.loader == "monolito") {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })
    (lib.mkIf (config.arranque.loader == "dual-boot") {
      boot.loader.grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        efiInstallAsRemovable = true;
      };
      boot.loader.efi.canTouchEfiVariables = false;
    })
  ]);
}
