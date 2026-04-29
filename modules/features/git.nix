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
        init.defaultBranch = "master";
        credential.helper = "store";

        transfer.fsckObjects = true;
        core.autocrlf = false;
        core.editor = "nvim";
        pull.rebase = true;
        push.autoSetupRemote = true;
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        core.untrackedCache = true;
        core.fsmonitor = true;
      };
    };
  };
}
