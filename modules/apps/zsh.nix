# modules/apps/zsh.nix
{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "docker" "sudo" ];
      theme = "robbyrussell";
    };
    interactiveShellInit = ''
      zstyle ':completion:*' menu no
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.zcompcache
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';
  };
}
