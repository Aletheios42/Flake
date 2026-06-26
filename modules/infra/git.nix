{ pkgs, lib, config, ... }:
{
  options.git = {
    enable = lib.mkEnableOption "Habilita git , requiere de tu email y usuario";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Tu usuario de github";
    };
    githubToken = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Si activar el secreto github/token para credential store";
    };
  };

  config = lib.mkIf(config.git.enable) {
    assertions = [{
      assertion = config.mi_sops.enable;
      message = "Git requiere sops para gestionar el email";
    }];

    sops.secrets."git/email" = {};
    sops.secrets."github/token" = lib.mkIf config.git.githubToken {};

    programs.git = {
      enable = true;
      config = {
        user.name = config.git.name;
        init.defaultBranch = "master";
        credential.helper = "store --file=${config.vars.home}/.config/git/credentials";

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

    system.activationScripts.gitConfig = {
      deps = [ "persist-files" "users" "setupSecrets" ];
      text = ''
      mkdir -p ${config.vars.home}/.config/git
      email=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."git/email".path} 2>/dev/null || echo "INSERT_EMAIL")
      ${lib.optionalString config.git.githubToken ''
      token=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."github/token".path} 2>/dev/null || echo "")
      ''}

      ${pkgs.coreutils}/bin/cat > ${config.vars.home}/.config/git/config <<EOF
      [user]
          email = "$email"
      EOF

      # Pre-popular credenciales git para GitHub (credential.helper = store)
      ${lib.optionalString config.git.githubToken ''
      if [ -n "$token" ]; then
        echo "https://${config.git.name}:$token@github.com" > ${config.vars.home}/.config/git/credentials
      fi
      ''}

      ${pkgs.coreutils}/bin/chown -R ${config.vars.usuarioPrincipal}:${config.vars.usuarioPrincipal} ${config.vars.home}/.config/git
      ${pkgs.coreutils}/bin/chown ${config.vars.usuarioPrincipal}:${config.vars.usuarioPrincipal} ${config.vars.home}/.config/git/credentials 2>/dev/null || true
    '';
    };

    myImpermanence.users.${config.vars.usuarioPrincipal} = {
      directories = [ ".config/git" ];
    };
  };
}
