{ pkgs, lib, config, ... }:
let
  defaultBrowser = 
    if config.navegadores.librewolf then "firefox.desktop"
    else if config.navegadores.chromiun then "qutebrowser.desktop"
    else if config.navegadores.qutebrowser then "qutebrowser.desktop"
    else "tor-browser";
in
{
  options.navegadores = {
    enable = lib.mkEnableOption "Modulo para selecionar los navegadores que quieres disponibles";
    librewolf = lib.mkEnableOption "Activa librewolf  politicas";
    chromiun = lib.mkEnableOption "Activa chromiun";
    tor = lib.mkEnableOption "Activa librewolf  politicas";
    qutebrowser = lib.mkEnableOption "Activa librewolf con politicas";
  };

  config = lib.mkIf (config.navegadores.enable) (lib.mkMerge [
    {
      assertions = [{
        assertion = config.navegadores.librewolf || config.navegadores.tor || config.navegadores.qutebrowser;
        message = "debes activar al menos un navegador";
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

    (lib.mkIf (config.navegadores.tor) {
      userPackages.navegadores = [pkgs.tor pkgs.tor-browser];
    })

    (lib.mkIf (config.navegadores.chromiun) {
      userPackages.navegadores = [ pkgs.chromium ];
      programs.chromium = {
        enable = true;

        # --- EXTENSIONES ---
        # En Chromium, las extensiones se instalan indicando su ID de la Chrome Web Store
        extensions = [
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
          "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
          "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
        ];

        extraOpts = {
          # 1. Configurar DuckDuckGo como buscador principal
          DefaultSearchProviderEnabled = true;
          DefaultSearchProviderName = "DuckDuckGo";
          DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
          DefaultSearchProviderNewTabURL = "https://duckduckgo.com/";
          DefaultSearchProviderKeyword = "duckduckgo.com";

          # Opcional: Evitar pantallas de inicio de sesión de Google si buscas máxima privacidad
          BrowserSignin = 0;
          SyncDisabled = true;

          # 2. Configuración de uBlock Origin
          "3rdparty".extensions."cjpalhdlnbpafiamejdnhcphjbkeiagm".adminSettings = {
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
    })

    (lib.mkIf (config.navegadores.librewolf) {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;

        policies = {

          SearchEngines = {
            Default = "DuckDuckGo";
            PreventInstalls = true;
          };
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

            "idcac-pub@guus.ninja" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi";
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

    (lib.mkIf (config.navegadores.qutebrowser) {
      environment.etc."xdg/qutebrowser/config.py".text = ''
          config.load_autoconfig(False)
          c.colors.webpage.preferred_color_scheme = 'dark'
          c.colors.webpage.darkmode.enabled = True
      '';
      userPackages.navegadores = [
        pkgs.qutebrowser
      ];
    })
  ]);
}
