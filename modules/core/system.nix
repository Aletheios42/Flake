{ pkgs, ...}:
{
  system.stateVersion = "25.11";
  nix.settings.download-buffer-size = 524288000; # 500MB
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;
  i18n.defaultLocale = "es_ES.UTF-8";
  documentation = {
    enable = true;
    man.enable = true;
    man.cache.enable = false;      # genera whatis db, acelera apropos que son LENTISIMOS en el rebuild
    info.enable = true;           # páginas GNU info
    nixos.enable = true;          # nixos-help y opciones locales
    doc.enable = true;            # HTML docs de paquetes
  };
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enableZshIntegration = true;

  environment.systemPackages = [
    pkgs.python3
    pkgs.git
    pkgs.openssl
    pkgs.neovim
    pkgs.tree pkgs.ripgrep pkgs.fd pkgs.bat pkgs.lsd
    pkgs.zip pkgs.unzip
    pkgs.tldr
    pkgs.ethtool pkgs.dnsutils pkgs.net-tools pkgs.fping pkgs.netcat
  ];
  environment.variables = { 
    EDITOR="nvim";
    VISUAL="nvim";
    PAGER="less";
    MANPAGER="less";
  }; # variables de entorno sistema
  environment.shellAliases = {}; # aliases globales
  environment.pathsToLink = [
    "/share/zsh" # util para completions
  ];  # expone paths del store

}
