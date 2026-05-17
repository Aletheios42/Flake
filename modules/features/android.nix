{ pkgs, config, lib, ... }:
{
  options.android.enable = lib.mkEnableOption "activa conectar el movil al ordenador";

  config = lib.mkIf(config.android.enable) {
    userPackages.android = [ pkgs.android-tools ];
  };
}
