{ lib, config, ... }:
{
  options.bluetooth = {
    enable = lib.mkEnableOption "Activa el bluetooth";
    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      description = "Activa el bluetooth al encender";
      default = false;
    };
  };

  config = lib.mkIf config.bluetooth.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = config.bluetooth.powerOnBoot;
  };
}
