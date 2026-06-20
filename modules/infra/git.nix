{ pkgs, lib, config, ... }:
let
  forge-cli = pkgs.stdenv.mkDerivation {
    name = "forge-0.5.1";
    src = pkgs.fetchurl {
      url    = "https://github.com/git-pkgs/forge/releases/download/v0.5.1/forge_0.5.1_linux_amd64.tar.gz";
      sha256 = "18n3rz6pqk4iarmk7gm6kkd4b9sxw7hx4n497c5rgycd6kn85ip9";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      tar xzf $src
      cp forge $out/bin/forge
    '';
  };
in
{
  options.git = {
    enable = lib.mkEnableOption "Habilita git , requiere de tu email y usuario";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Tu usuario de github";
    };
  };

  config = lib.mkIf(config.git.enable) {
    assertions = [{
      assertion = config.mi_sops.enable;
      message = "Git requiere sops para gestionar el email";
    }];

    sops.secrets."git/email" = {};

    userPackages.git = [ forge-cli ];

    programs.git = {
      enable = true;
      config = {
        user.name = config.git.name;
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

    system.activationScripts.gitConfig = ''
      mkdir -p ${config.vars.home}/.config/git
      email=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."git/email".path} 2>/dev/null || echo "INSERT_EMAIL")

      ${pkgs.coreutils}/bin/cat > ${config.vars.home}/.config/git/config <<EOF
      [user]
          email = "$email"
      EOF

      ${pkgs.coreutils}/bin/chown -R ${config.vars.usuarioPrincipal}:${config.vars.usuarioPrincipal} ${config.vars.home}/.config/git
    '';

    myImpermanence.users.${config.vars.usuarioPrincipal} = {
      directories = [ ".config/git" ];
    };
  };
}
