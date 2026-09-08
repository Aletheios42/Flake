{ pkgs, lib, config, ... }:
let
  user = config.usuarioPrincipal;
  ublockFilters = [
    "user-filters" "ublock-filters" "ublock-badware" "ublock-privacy"
    "ublock-quick-fixes" "ublock-unbreak" "easylist" "easyprivacy"
    "urlhaus-1" "plowe-0"
    "adguard-cookies" "fanboy-cookiemonster" "ublock-annoyances"
  ];
in
{
  options.navegadores.chromium = {
    enable = lib.mkEnableOption "Activa Chromium con extensiones y políticas";
    default = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Establece Chromium como navegador predeterminado en XDG MIME";
    };
  };

  config = lib.mkIf config.navegadores.chromium.enable {
    userPackages.navegadores = [ pkgs.chromium ];
    nixpkgs.config.chromium.commandLineArgs = [ "--force-dark-mode" "--enable-features=WebUIDarkMode" ];

    programs.chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
        "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
      ];
      extraOpts = {
        PasswordManagerEnabled = false;
        DefaultSearchProviderEnabled   = true;
        DefaultSearchProviderName      = "DuckDuckGo";
        DefaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderNewTabURL = "https://duckduckgo.com/";
        DefaultSearchProviderKeyword   = "duckduckgo.com";
        BrowserSignin = 0;
        SyncDisabled  = true;
        "3rdparty".extensions = {
          "cjpalhdlnbpafiamejdnhcphjbkeiagm".adminSettings = {
            toOverwrite.filterLists = ublockFilters;
          };
        }; 
      };
    };

    xdg.mime = lib.mkIf config.navegadores.chromium.default {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http"  = "chromium.desktop";
        "x-scheme-handler/https" = "chromium.desktop";
      };
    };

    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".config/chromium"; mode = "0755";}
          { directory = ".cache/chromium"; mode = "0755";}
        ];
      };
  };
}
