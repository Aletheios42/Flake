{ pkgs, ...}:
{
  userPackages.shell = [
    pkgs.rofi pkgs.kitty pkgs.tmux 
    pkgs.fzf pkgs.ranger
  ];
}
