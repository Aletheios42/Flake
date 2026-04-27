{ pkgs, lib, config , ... }:
{
  options.obs.enable = lib.mkEnableOption "Activa obs proximamente con sus scripts";

  config = lib.mkIf (config.obs.enable)  {
    userPackages.obs = [
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs obs-vkcapture input-overlay
        ];
      })
    ];
  };
}
