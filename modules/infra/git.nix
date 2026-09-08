{ pkgs, lib, config, ... }:
let
  home = config.users.users.${config.usuarioPrincipal}.home;
in
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
      assertion = config.sops.enable;
      message = "Git requiere sops para gestionar el email";
    }];
    sops.secrets."git/email" = {};
    sops.secrets."github/token" = lib.mkIf config.git.githubToken {};
    programs.git = {
      enable = true;
      config = {
        user.name = config.git.name;
        init.defaultBranch = "master";
        credential.helper = "store --file=${home}/.config/git/credentials";
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
      mkdir -p ${home}/.config/git
      ${pkgs.coreutils}/bin/chmod 700 ${home}/.config/git  # nuevo: restringe acceso al directorio (contendrá credenciales)
      email=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."git/email".path} 2>/dev/null || echo "INSERT_EMAIL")
      ${lib.optionalString config.git.githubToken ''
      token=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."github/token".path} 2>/dev/null || echo "")
      ''}
      ${pkgs.coreutils}/bin/cat > ${home}/.config/git/config <<EOF
      [user]
          email = "$email"
      EOF
      ${pkgs.coreutils}/bin/chmod 600 ${home}/.config/git/config  # nuevo: config con email, restringir lectura
      # Pre-popular credenciales git para GitHub (credential.helper = store)
      ${lib.optionalString config.git.githubToken ''
      if [ -n "$token" ]; then
        echo "https://${config.git.name}:$token@github.com" > ${home}/.config/git/credentials
        ${pkgs.coreutils}/bin/chmod 600 ${home}/.config/git/credentials  # nuevo: token en texto plano, solo owner debe leer
      fi
      ''}
      ${pkgs.coreutils}/bin/chown -R ${config.usuarioPrincipal}:${config.usuarioPrincipal} ${home}/.config/git
      ${pkgs.coreutils}/bin/chown ${config.usuarioPrincipal}:${config.usuarioPrincipal} ${home}/.config/git/credentials 2>/dev/null || true
    '';
    };
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf config.impermanencia.enable {
        directories = [
          { directory = ".config/git"; mode = "0700"; }
        ];
      };
  };
}
