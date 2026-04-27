{ pkgs, lib, config, ...}:
{
  options.pantalla.enable = lib.mkEnableOption "Carga nerd-font y pone la tty en español";

  config = lib.mkIf (config.pantalla.enable) {
    console.keyMap = "es";
    console.earlySetup = true;

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.fira-code
  ];

  };
}
