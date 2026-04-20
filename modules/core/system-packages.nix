{pkgs, ...}:
{
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
