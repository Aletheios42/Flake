# modules/apps/tmux.nix
{ pkgs, ... }:
let
  tmuxConf = pkgs.writeText "tmux.conf" ''
    set -g clock-mode-style 24
    set -sg escape-time 10
    set -g @plugin 'tmux-plugins/tmux-resurrect'
    set -g @resurrect-strategy-nvim 'session'
  '';
in
{
  userPackages.tmux = [
    (pkgs.symlinkJoin {
      name = "tmux";
      paths = [ pkgs.tmux pkgs.tmuxPlugins.vim-tmux-navigator pkgs.tmuxPlugins.resurrect ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/tmux \
          --add-flags "-f ${tmuxConf}"
      '';
    })
  ];
}
