{...}:
{
  boot = {
    supportedFilesystems = ["ntfs"];
    kernel.sysctl = {
      "kernel.perf_event_paranoid" = -1;
    };
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
      efi.efiSysMountPoint = "/boot/";
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = false;
        efiInstallAsRemovable = true; 
        extraEntries = ''
         "Windows 11" {
            search --set=root --file /EFI/Microsoft/Boot/bootmgfw-original.efi
            chainloader /EFI/Microsoft/Boot/bootmgfw-original.efi
          }
        '';
      };
    };
  };
}
