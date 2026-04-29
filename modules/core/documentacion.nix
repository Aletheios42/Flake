{ lib, config, ...}:
{
  options.documentacion.enable = lib.mkEnableOption "Este bloque activo man e info";

  config = lib.mkIf (config.documentacion.enable) {
    documentation = {
      enable = true;
      man.enable = true;
      man.cache.enable = false;     # genera whatis db, acelera apropos que son LENTISIMOS en el rebuild
      info.enable = true;           # páginas GNU info
      nixos.enable = true;          # nixos-help y opciones locales
      doc.enable = true;            # HTML docs de paquetes
    };
  };
}
