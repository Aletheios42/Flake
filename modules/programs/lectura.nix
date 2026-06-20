{ pkgs, lib , config, ...}:
{
  options.lectura = {
    enable = lib.mkEnableOption "Activa paquetas de lectura";
    calibre = lib.mkEnableOption "Activa calibre";
    zathura = lib.mkEnableOption "Aciva zathura";
    koreader = lib.mkEnableOption "Activa koreader";
  };

  config = lib.mkIf (config.lectura.enable) (lib.mkMerge [
    {
      assertions = [{
        assertion = config.lectura.calibre || config.lectura.zathura || config.lectura.koreader;
        message = "Debes activar al menos una herramienta de lectura (calibre, zathura o koreader)";
      }];
    }
    (lib.mkIf (config.lectura.zathura) {
      userPackages.lectura = [ pkgs.zathura ];
    })
    (lib.mkIf (config.lectura.koreader)  {
      userPackages.lectura = [ pkgs.koreader ];
    })
    (lib.mkIf (config.lectura.calibre)  {
      userPackages.lectura = [ pkgs.calibre ];
    })
  ]);
}
