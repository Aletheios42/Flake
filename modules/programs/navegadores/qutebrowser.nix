{ pkgs, lib, config, ... }:
{
  options.navegadores.qutebrowser = {
    enable = lib.mkEnableOption "Activa Qutebrowser";
    default = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Establece Qutebrowser como navegador predeterminado en XDG MIME";
    };
  };

  config = lib.mkIf config.navegadores.qutebrowser.enable {
    userPackages.navegadores = [ pkgs.qutebrowser ];

    environment.etc."xdg/qutebrowser/config.py".text = ''
      config.load_autoconfig(False)
      c.colors.webpage.preferred_color_scheme = 'dark'
      c.colors.webpage.darkmode.enabled = True
      c.downloads.location.directory = '/home/aletheios42/Descargas'
      c.downloads.location.suggestion = 'never'

      # Ranger como explorador de archivos
      c.fileselect.handler = 'external'
      c.fileselect.single_file.command = ['kitty', '-e', 'ranger', '--choosefile={}']
      c.fileselect.multiple_files.command = ['kitty', '-e', 'ranger', '--choosefiles={}']
      c.fileselect.folder.command = ['kitty', '-e', 'ranger', '--choosedir={}']

      # Atajos para integración con Vaultwarden CLI (rbw)
      config.bind(',p', 'spawn --userscript qute-rbw')
      config.bind(',P', 'spawn --userscript qute-rbw --password-only')
      config.bind(',u', 'spawn --userscript qute-rbw --username-only')
    '';

    xdg.mime = lib.mkIf config.navegadores.qutebrowser.default {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http"  = "qutebrowser.desktop";
        "x-scheme-handler/https" = "qutebrowser.desktop";
      };
    };

    environment.persistence."/persist".users.${config.usuarioPrincipal} = 
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          {directory = ".config/qutebrowser"; mode = "0755";}
          {directory = ".cache/qutebrowser"; mode = "0755";}
          {directory = ".local/share/qutebrowser"; mode = "0755";}
        ];
      };
  };
}
