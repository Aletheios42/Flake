{ pkgs, lib, config, ... }:
{
  options.userPackages = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.package);
    default = {};
  };
  options.usuarios = lib.mkOption {
    type = lib.types.attrsOf ( lib.types.submodule {
      options = {
        hashedPasswordFile = lib.mkOption {
          type = lib.types.str;
          description = "Ruta al archivo con la contraseña hasheada del usuario (gestionado por sops)";
        };
        grupos = lib.mkOption {
          type = lib.types.listOf (lib.types.str);
          default = [];
          description = "Grupos a los que pertenecera el usuario";
        };
        llavesSsh = lib.mkOption {
          type = lib.types.listOf (lib.types.str);
          default = [];
          description = "Llaves ssh con la que logearte de forma remota con este usuario";
        };
        shell = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zsh;
          description = "Shell asociada al usuario";
        };
      };
    });
    default = {};
    description = "Usuario necesita contraseña, grupos, llaves ssh y terminal";
  };

  config = lib.mkIf (config.usuarios != {}) {
    assertions = [{
      assertion = lib.any (u: lib.elem "wheel" u.grupos) (lib.attrValues config.usuarios);
      message = "Debe haber al menos un usuario con grupo wheel";
    }];

    users.groups = lib.mapAttrs (nombre: _: {}) config.usuarios;
    users.mutableUsers = false;

    users.users = lib.mapAttrs (nombre: userConf: {
      hashedPasswordFile = userConf.hashedPasswordFile;
      group = nombre;
      extraGroups = userConf.grupos;
      shell = userConf.shell;
      isNormalUser = true;
      openssh.authorizedKeys.keys = userConf.llavesSsh;
      packages = lib.flatten (lib.attrValues config.userPackages);
    }) config.usuarios;

    sops.secrets = lib.mapAttrs' (nombre: _: {
      name = "users/${nombre}_password";
      value = {};
    }) config.usuarios;
  };
}
