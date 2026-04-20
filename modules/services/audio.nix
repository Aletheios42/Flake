{...}:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # Compatibilidad con apps viejas y OBS
    wireplumber.enable = true; # Para auidio con bluetooth
  };
}
