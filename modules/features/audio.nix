{ lib, config, ...}:
{
  options.audio = {
    enable = lib.mkEnableOption "audio";
  };

  config = lib.mkIf config.audio.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true; # Compatibilidad con apps viejas y OBS
      wireplumber.enable = true; # Para auidio con bluetooth
    };
  };
}
