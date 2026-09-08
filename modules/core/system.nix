{ pkgs, lib, config, ...}:
{
  options.sistema = {
    enable = lib.mkEnableOption "Variables";
  };

  config = lib.mkIf (config.sistema.enable) {
    security.sudo.wheelNeedsPassword = false;

    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
    programs.nix-index.enableZshIntegration = true;

    i18n.defaultLocale = "es_ES.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS        = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT    = "es_ES.UTF-8";
      LC_MONETARY       = "es_ES.UTF-8";
      LC_NAME           = "es_ES.UTF-8";
      LC_NUMERIC        = "es_ES.UTF-8";
      LC_PAPER          = "es_ES.UTF-8";
      LC_TELEPHONE      = "es_ES.UTF-8";
      LC_TIME           = "es_ES.UTF-8";
    };

    environment.systemPackages = [
      pkgs.lm_sensors
      pkgs.python3
      pkgs.git
      pkgs.neovim
      pkgs.openssl pkgs.xxd
      pkgs.zip pkgs.unzip
      pkgs.btop pkgs.systemd-manager-tui  pkgs.wget 
      pkgs.ethtool pkgs.dnsutils pkgs.net-tools pkgs.fping pkgs.netcat
      pkgs.xdg-user-dirs
    ];

    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    environment.variables = {
      EDITOR    = "nvim";
      VISUAL    = "nvim";
      PAGER     = "less";
      MANPAGER  = "less";
      GTK_THEME = "Adwaita:dark";
    };
    environment.shellAliases = {};
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
