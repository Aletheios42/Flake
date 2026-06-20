{ pkgs, lib, config, ... }:
let
  defaultBrowser = 
    if config.navegadores.firefox then "firefox.desktop"
    else if config.navegadores.chromiun then "chromium.desktop"
    else if config.navegadores.qutebrowser then "qutebrowser.desktop"
    else "tor-browser";
in
{
  options.navegadores = {
    enable = lib.mkEnableOption "Modulo para selecionar los navegadores que quieres disponibles";
    firefox = lib.mkEnableOption "Activa firefox con politicas";
    chromiun = lib.mkEnableOption "Activa chromiun";
    tor = lib.mkEnableOption "Activa Tor Browser";
    qutebrowser = lib.mkEnableOption "Activa qutebrowser";
  };

  config = lib.mkIf (config.navegadores.enable) (lib.mkMerge [
    {
      assertions = [{
        assertion = config.navegadores.firefox || config.navegadores.chromiun
               || config.navegadores.tor || config.navegadores.qutebrowser;
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

      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".local/share/tor-browser" ];
      };

    })

    (lib.mkIf (config.navegadores.chromiun) {
      userPackages.navegadores = [ pkgs.chromium ];
      nixpkgs.config.chromium.commandLineArgs = [ "--force-dark-mode" "--enable-features=WebUIDarkMode" ];

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
          # Configurar DuckDuckGo como buscador principal
          DefaultSearchProviderEnabled = true;
          DefaultSearchProviderName = "DuckDuckGo";
          DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
          DefaultSearchProviderNewTabURL = "https://duckduckgo.com/";
          DefaultSearchProviderKeyword = "duckduckgo.com";

          # Opcional: Evitar pantallas de inicio de sesión de Google si buscas máxima privacidad
          BrowserSignin = 0;
          SyncDisabled = true;

          # Configuración de uBlock Origin
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

      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/chromium" ".cache/chromium" ];
      };

    })

    (lib.mkIf (config.navegadores.firefox) {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;

        policies = {
          SearchEngines = {
            Default = "DuckDuckGo";
            PreventInstalls = true;
          };
          Preferences = {
            "ui.systemUsesDarkTheme"        = 1;
            "browser.theme.content-theme"   = 0;
            "browser.theme.toolbar-theme"   = 0;
          };

          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url        = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode  = "force_installed";
            };
            "keepassxc-browser@keepassxc.org" = {
              install_url        = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
              installation_mode  = "force_installed";
            };
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url        = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode  = "force_installed";
            };
            "idcac-pub@guus.ninja" = {
              install_url        = "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi";
              installation_mode  = "force_installed";
            };
          };

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

      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".mozilla/firefox" ];
      };
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

      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/qutebrowser" ".cache/qutebrowser" ".local/share/qutebrowser" ];
      };
    })

  ]);
}
