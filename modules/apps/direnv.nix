# modules/apps/direnv.nix
{ pkgs, ... }:
{
  userPackages.direnv = [ pkgs.direnv pkgs.nix-direnv ];
  programs.zsh.interactiveShellInit = ''
    eval "$(direnv hook zsh)"
  '';
}
