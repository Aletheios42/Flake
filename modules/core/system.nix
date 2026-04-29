{ pkgs, lib, config,  ...}:
{
  options.sistema = {
    enable = lib.mkEnableOption "Variables";
    version = lib.mkOption {
      type = lib.types.str;
      default = "26.05";
      description = "pon la version de nixos que quieres usar";
    };
  };

  config = lib.mkIf (config.sistema.enable) {
    assertions = [{
      assertion = config.sistema.version != "";
      message = "No es una variable valida";
    }];
    system.stateVersion = config.sistema.version;
    nix.settings.download-buffer-size = 524288000; # 500MB
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
    programs.nix-index.enableZshIntegration = true;

    i18n.defaultLocale = "es_ES.UTF-8";
    # LANGUAGE = (unset),
    #     LC_ALL = (unset),
    #     LC_CTYPE = (unset),
    #     LC_NUMERIC = (unset),
    #     LC_COLLATE = (unset),
    #     LC_TIME = (unset),
    #     LC_MESSAGES = (unset),
    #     LC_MONETARY = (unset),
    #     LC_ADDRESS = (unset),
    #     LC_IDENTIFICATION = (unset),
    #     LC_MEASUREMENT = (unset),
    #     LC_PAPER = (unset),
    #     LC_TELEPHONE = (unset),
    #     LC_NAME = (unset),
    #     LANG = "es_ES.UTF-8"

    environment.systemPackages = [
      pkgs.python3
      pkgs.git
      pkgs.openssl
      pkgs.neovim
      pkgs.zip pkgs.unzip
      pkgs.ethtool pkgs.dnsutils pkgs.net-tools pkgs.fping pkgs.netcat
    ];

    environment.variables = { 
      EDITOR="nvim";
      VISUAL="nvim";
      PAGER="less";
      MANPAGER="less";
    };
    environment.shellAliases = {};
    environment.pathsToLink = [
      "/share/zsh" # util para completions
    ];
  };
}
