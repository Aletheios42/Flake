{ pkgs, lib, config, ... }:
{
  options.obsidian.enable = lib.mkEnableOption "Activo Obsidian";

  config = lib.mkIf (config.obsidian.enable) {
    userPackages.obsidian = [ pkgs.obsidian];
    myImpermanence.users.${config.vars.usuarioPrincipal} = {
      directories = [ "Documentos/Obsidian" ".config/obsidian" ];
    };
  };
}
