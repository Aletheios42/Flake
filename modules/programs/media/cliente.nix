{ pkgs, lib, config, ... }:
{
  options.media.cliente = lib.mkEnableOption "Activa paquetes multimedia y OBS";

  config = lib.mkIf config.media.cliente {
    userPackages.media = [
      pkgs.pavucontrol
      pkgs.vlc
      pkgs.mpv
      pkgs.ffmpeg
      pkgs.ardour
      pkgs.blender
      pkgs.grayjay
      pkgs.nuclear
    ];

    userPackages.obs = [
      (pkgs.wrapOBS {
        plugins = [
          pkgs.obs-studio-plugins.wlrobs
          pkgs.obs-studio-plugins.obs-vkcapture
          pkgs.obs-studio-plugins.input-overlay
        ];
      })
    ];

    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".local/share/Grayjay"; mode = "0755";}
          { directory = ".config/blender"; mode = "0755";}
          { directory = ".config/obs-studio"; mode = "0755";}
          { directory = ".config/vlc"; mode = "0755";}
          { directory = ".local/state/mpv"; mode = "0755";}
        ];
      };
  };
}
