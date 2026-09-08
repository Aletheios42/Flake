{ pkgs, lib, config, ... }:
{
  options.shell.direnv = lib.mkOption { type = lib.types.bool; default = true; description = "activa direnv con nix-direnv"; };

  config = lib.mkIf config.shell.direnv {
    userPackages.direnv = [ pkgs.direnv pkgs.nix-direnv ];
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [{ directory = ".config/direnv"; mode = "0755";}];
      };
  };
}
