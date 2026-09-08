{ pkgs, lib, config, ... }:
let
  tmuxConf = pkgs.writeText "tmux.conf" ''
    set -g clock-mode-style 24
    set -sg escape-time 10
    set -g base-index 1
    set -g pane-base-index 1

    set -g @resurrect-dir '~/.local/share/tmux/resurrect'
    run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '15'
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
    run-shell ${pkgs.tmuxPlugins.vim-tmux-navigator}/share/tmux-plugins/vim-tmux-navigator/vim-tmux-navigator.tmux
  '';
  tmuxPkg = pkgs.symlinkJoin {
    name = "tmux";
    paths = [ pkgs.tmux ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/tmux --add-flags "-f ${tmuxConf}"
    '';
  };
in
{
  options.shell.tmux = lib.mkOption { type = lib.types.bool; default = true; description = "activa tmux"; };

  config = lib.mkIf config.shell.tmux {
    userPackages.tmux = [ tmuxPkg ];
    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [
          { directory = ".config/tmux"; mode = "0755";}
          { directory = ".local/share/tmux"; mode = "0755";}
        ];
      };
  };
}
