{ pkgs, lib, config, ... }:
{

  options.userPackages = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.package);
    default = {};
  };
  options.usuarios = lib.mkOption {
    type = lib.types.attrsOf ( lib.types.submodule {
      options = {
        hashedPassword = lib.mkOption {
          type = lib.types.str;
          description = "Contraseña hasheada del usuario";
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
      hashedPassword = userConf.hashedPassword;
      group = nombre;
      extraGroups = userConf.grupos;
      shell = userConf.shell;
      isNormalUser = true;
      openssh.authorizedKeys.keys = userConf.llavesSsh;
      packages = lib.flatten (lib.attrValues config.userPackages);
    }) config.usuarios;
  };
}
