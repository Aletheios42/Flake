{ lib, ... }:
{
  options.vars = {
    dominio = lib.mkOption {
      type = lib.types.str;
      description = "dominio del servidor";
      default = "";
    };
  };
}
