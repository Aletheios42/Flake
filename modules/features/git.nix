{ lib, config, ... }:
{
  options.git = {
    enable = lib.mkEnableOption "Habilita git , requiere de tu email y usuario";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Tu usuario de github";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Tu email de github";
    };
  };

  config = lib.mkIf(config.git.enable) {
    programs.git = {
      enable = true;
      config = {
        user.name = config.git.name;
        user.email = config.git.email;
        init.DefaultBranch = "master";
        credential.helper = "store";
      };
    };
  };
}
