# modules/apps/obs.nix
{ pkgs, ... }:
{
  userPackages.obs = [
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs obs-vkcapture input-overlay
      ];
    })
  ];
}
