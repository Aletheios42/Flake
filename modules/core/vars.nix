{ config, lib, ... }:
{
  options.vars = {
    dominio = lib.mkOption {
      type = lib.types.str;
      description = "dominio del servidor";
      default = "";
    };
    usuarioPrincipal = lib.mkOption {
      type = lib.types.str;
      default = "aletheios42";
      description = "Nombre del usuario principal del sistema";
    };
    home = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.vars.usuarioPrincipal}";
      description = "Ruta al home del usuario principal";
    };
  };
}
