{ pkgs, lib, config, ... }:
let
  defaultBrowser = 
    if config.navegadores.librewolf then "firefox.desktop"
    else if config.navegadores.qutebrowser then "qutebrowser.desktop"
    else "google-chrome.desktop";
in
{
  options.navegadores = {
    enable = lib.mkEnableOption "Modulo para selecionar los navegadores que quieres disponibles";
    librewolf = lib.mkEnableOption "Activa librewolf con politicas";
    google-chrome = lib.mkEnableOption "Activa librewolf con politicas";
    qutebrowser = lib.mkEnableOption "Activa librewolf con politicas";
  };

  config = lib.mkIf (config.navegadores.enable) (lib.mkMerge [
    {
      assertions = [{
        assertion = config.navegadores.librewolf || config.navegadores.google-chrome || config.navegadores.qutebrowser;
        message = "Debes activar al menos un navegador";
      }];
    }
    {
      xdg.mime = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = defaultBrowser;
          "x-scheme-handler/https" = defaultBrowser;
        };
      };
    }
    (lib.mkIf (config.navegadores.librewolf) {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;

        policies = {
          Preferences = {
            "ui.systemUsesDarkTheme" = 1;
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
          };

          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
            "keepassxc-browser@keepassxc.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
              installation_mode = "force_installed";
            };
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode = "force_installed";
            };
          };

          # --- LISTAS DE UBLOCK ORIGIN (CON COOKIES Y MOLESTIAS) ---
          "3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = {
            toOverwrite = {
              filterLists = [
                "user-filters" "ublock-filters" "ublock-badware" "ublock-privacy" 
                "ublock-quick-fixes" "ublock-unbreak" "easylist" "easyprivacy" 
                "urlhaus-1" "plowe-0"
                "adguard-cookies" "fanboy-cookiemonster" "ublock-annoyances"
              ];
            };
          };
        };
      };
      # Sincronizamos la política general de Firefox hacia LibreWolf
      environment.etc."librewolf/policies/policies.json".source = config.environment.etc."firefox/policies/policies.json".source;
    })

    (lib.mkIf (config.navegadores.google-chrome) {
      nixpkgs.config.allowUnfree = true;
    })

    (lib.mkIf (config.navegadores.qutebrowser) {
      environment.etc."xdg/qutebrowser/config.py".text = ''
          config.load_autoconfig(False)
          c.colors.webpage.preferred_color_scheme = 'dark'
          c.colors.webpage.darkmode.enabled = True
      '';
      userPackages.browsers = [
        pkgs.qutebrowser
        (pkgs.google-chrome.override { 
          commandLineArgs = "--force-dark-mode --enable-features=WebUIDarkMode"; 
        })
      ];
    })
  ]);
}
