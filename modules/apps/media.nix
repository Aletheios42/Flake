{pkgs, ...}:
{
  userPackages.media = [
    pkgs.grayjay
    pkgs.musikcube pkgs.pavucontrol
    pkgs.vlc pkgs.mpv pkgs.ffmpeg
  ];
}
