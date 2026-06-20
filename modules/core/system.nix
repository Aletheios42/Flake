{ pkgs, lib, config, ...}:
{
  options.sistema = {
    enable = lib.mkEnableOption "Variables";
    version = lib.mkOption {
      type = lib.types.str;
      description = "Versión de NixOS desde la instalación inicial. NO cambiar tras el primer deploy.";
    };
  };

  config = lib.mkIf (config.sistema.enable) {
    assertions = [{
      assertion = config.sistema.version != "";
      message = "sistema.version no puede estar vacío";
    }];

    system.stateVersion = config.sistema.version;
    nix.settings.download-buffer-size = 524288000; # 500MB
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;

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
      pkgs.python3
      pkgs.git
      pkgs.neovim
      pkgs.openssl
      pkgs.zip pkgs.unzip
      pkgs.ethtool pkgs.dnsutils pkgs.net-tools pkgs.fping pkgs.netcat
    ];

    environment.variables = {
      EDITOR    = "nvim";
      VISUAL    = "nvim";
      PAGER     = "less";
      MANPAGER  = "less";
      GTK_THEME = "Adwaita:dark";
    };
    environment.shellAliases = {};
    environment.pathsToLink = [
      "/share/zsh" # util para completions
    ];
  };
}
