{ pkgs, lib, config, ... }:
{
  options.direnv.enable = lib.mkEnableOption "Descarga direnv y se lo aplica a zsh";

  config = lib.mkIf (config.direnv.enable) {
    userPackages.direnv = [ pkgs.direnv pkgs.nix-direnv ];
    programs.zsh.interactiveShellInit = ''
      eval "$(direnv hook zsh)"
    '';
  };
}
