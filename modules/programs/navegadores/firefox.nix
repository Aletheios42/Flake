{ pkgs, lib, config, ... }:
let
  ublockFilters = [
    "user-filters" "ublock-filters" "ublock-badware" "ublock-privacy"
    "ublock-quick-fixes" "ublock-unbreak" "easylist" "easyprivacy"
    "urlhaus-1" "plowe-0"
    "adguard-cookies" "fanboy-cookiemonster" "ublock-annoyances"
  ];
in
{
  options.navegadores.firefox = {
    enable = lib.mkEnableOption "Activa Firefox con políticas declarativas";
    default = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Establece Firefox como navegador predeterminado en XDG MIME";
    };
  };

  config = lib.mkIf config.navegadores.firefox.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;
      policies = {
        PasswordManagerEnabled = false;
        SearchEngines = {
          Default = "DuckDuckGo";
          PreventInstalls = true;
        };
        Preferences = {
          "ui.systemUsesDarkTheme"      = 1;
          "browser.theme.content-theme" = 0;
          "browser.theme.toolbar-theme" = 0;
          "browser.download.dir"        = "/home/${config.usuarioPrincipal}/Descargas";
          "browser.download.folderList" = 2;
        };
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            install_url       = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
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
        "3rdparty".Extensions = {
          "uBlock0@raymondhill.net".adminSettings = {
            toOverwrite.filterLists = ublockFilters;
          };
        };
      };
    };

    xdg.mime = lib.mkIf config.navegadores.firefox.default {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http"  = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
      };
    };

    environment.persistence."/persist".users.${config.usuarioPrincipal} = 
      lib.mkIf (config.impermanencia.enable) {
        directories = [{ directory = ".mozilla/firefox"; mode = "0755";}];
      };
  };
}
