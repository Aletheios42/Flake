{ pkgs, lib, config, ... }:
let
  user = config.vars.usuarioPrincipal;
  defaultBrowser =
    if config.navegadores.firefox then "firefox.desktop"
    else if config.navegadores.chromiun then "chromium.desktop"
    else if config.navegadores.qutebrowser then "qutebrowser.desktop"
    else "tor-browser";

  # Listas de filtros compartidas entre Firefox y Chromium
  ublockFilters = [
    "user-filters" "ublock-filters" "ublock-badware" "ublock-privacy"
    "ublock-quick-fixes" "ublock-unbreak" "easylist" "easyprivacy"
    "urlhaus-1" "plowe-0"
    "adguard-cookies" "fanboy-cookiemonster" "ublock-annoyances"
  ];
in
{
  options.navegadores = {
    enable      = lib.mkEnableOption "Modulo para seleccionar los navegadores disponibles";
    firefox     = lib.mkEnableOption "Activa firefox con politicas";
    chromiun    = lib.mkEnableOption "Activa chromium";
    tor         = lib.mkEnableOption "Activa Tor Browser";
    qutebrowser = lib.mkEnableOption "Activa qutebrowser";
  };

  config = lib.mkIf config.navegadores.enable (lib.mkMerge [
    {
      assertions = [{
        assertion = config.navegadores.firefox || config.navegadores.chromiun
               || config.navegadores.tor || config.navegadores.qutebrowser;
        message = "debes activar al menos un navegador";
      }];

      xdg.mime = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http"  = defaultBrowser;
          "x-scheme-handler/https" = defaultBrowser;
        };
      };
    }

    # --- Tor Browser ---
    (lib.mkIf config.navegadores.tor {
      userPackages.navegadores = [ pkgs.tor pkgs.tor-browser ];
      myImpermanence.users.${user}.directories = [ ".local/share/tor-browser" ];
    })

    # --- Chromium ---
    (lib.mkIf config.navegadores.chromiun {
      userPackages.navegadores = [ pkgs.chromium ];
      nixpkgs.config.chromium.commandLineArgs = [ "--force-dark-mode" "--enable-features=WebUIDarkMode" ];

      programs.chromium = {
        enable = true;
        extensions = [
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
          "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
          "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
        ];
        extraOpts = {
          PasswordManagerEnabled = false;
          DefaultSearchProviderEnabled  = true;
          DefaultSearchProviderName     = "DuckDuckGo";
          DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
          DefaultSearchProviderNewTabURL = "https://duckduckgo.com/";
          DefaultSearchProviderKeyword  = "duckduckgo.com";
          BrowserSignin = 0;
          SyncDisabled  = true;
          "3rdparty".extensions."cjpalhdlnbpafiamejdnhcphjbkeiagm".adminSettings = {
            toOverwrite.filterLists = ublockFilters;
          };
        };
      };

      myImpermanence.users.${user}.directories = [ ".config/chromium" ".cache/chromium" ];
    })

    # --- Firefox ---
    (lib.mkIf config.navegadores.firefox {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
        policies = {
          PasswordManagerEnabled = false;
          SearchEngines = { Default = "DuckDuckGo"; PreventInstalls = true; };
          Preferences = {
            "ui.systemUsesDarkTheme"      = 1;
            "browser.theme.content-theme" = 0;
            "browser.theme.toolbar-theme" = 0;
            "browser.download.dir"        = "/home/${user}/Downloads";
            "browser.download.folderList"  = 2;
          };
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              install_url       = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
            "keepassxc-browser@keepassxc.org" = {
              install_url       = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
              installation_mode = "force_installed";
            };
            "jid1-MnnxcxisBPnSXQ@jetpack" = {
              install_url       = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
              installation_mode = "force_installed";
            };
            "idcac-pub@guus.ninja" = {
              install_url       = "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi";
              installation_mode = "force_installed";
            };
          };
          "3rdparty".Extensions."uBlock0@raymondhill.net".adminSettings = {
            toOverwrite.filterLists = ublockFilters;
          };
        };
      };

      myImpermanence.users.${user}.directories = [ ".mozilla/firefox" "Downloads" ];
    })

    # --- Qutebrowser ---
    (lib.mkIf config.navegadores.qutebrowser {
      environment.etc."xdg/qutebrowser/config.py".text = ''
        config.load_autoconfig(False)
        c.colors.webpage.preferred_color_scheme = 'dark'
        c.colors.webpage.darkmode.enabled = True
      '';
      userPackages.navegadores = [ pkgs.qutebrowser ];
      myImpermanence.users.${user}.directories = [
        ".config/qutebrowser" ".cache/qutebrowser" ".local/share/qutebrowser"
      ];
    })
  ]);
}
