{pkgs, lib, config, ...}:
{
  options.media.enable = lib.mkEnableOption "Activa grayjay musikcube pavucontrol vlc mpv ffmpef";

  config = lib.mkIf (config.media.enable) {
    userPackages.media = [
      pkgs.grayjay
      pkgs.musikcube pkgs.pavucontrol
      pkgs.vlc pkgs.mpv pkgs.ffmpeg
    ];
  };
}
