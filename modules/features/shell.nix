{ pkgs, lib, config, ... }:
let
  kittyConf = pkgs.writeText "kitty.conf" ''
    scrollback_line -1
    enable_audio_bell = no
  '';
  tmuxConf = pkgs.writeText "tmux.conf" ''
    set -g clock-mode-style 24
    set -sg escape-time 10
    set -g @plugin 'tmux-plugins/tmux-resurrect'
  '';
  zshConf = ''
    zstyle ':completion:*' menu no
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zcompcache
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
  '';
  rangerConf = pkgs.writeText "rc.conf" ''
    set show_hidden true
    map f shell find . -name "%s"
    set preview_images true
    set preview_images_method w3m
    map yy copy
    map dd cut
    map pp paste
  '';
in
  {
  options.shell = {
    enable = lib.mkEnableOption "Shell con todo el tooling";
    kitty = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa terminal kitty";
    };
    zsh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa terminal zsh";
    };
    ranger = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa terminal ranger";
    };
    cli = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa terminal kitty";
    };
    tmux = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa terminal tmux";
    };
  };

  config = lib.mkIf(config.shell.enable) (lib.mkMerge [
    (lib.mkIf (config.shell.kitty) {
      userPackages.kitty = [ (
        pkgs.symlinkJoin { name = "kitty";
          paths = [pkgs.kitty];
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
          wrapProgram $out/bin/kitty \
          --add-flags "--config ${kittyConf}"}
          '';}
          )];
        })
          (lib.mkIf (config.shell.cli) {
          userPackages.shell = [ pkgs.ripgrep pkgs.fd pkgs.fzf pkgs.bat pkgs.lsd ];
          })
          (lib.mkIf (config.shell.zsh) {
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
          interactiveShellInit = zshConf;
          };
          })
          (lib.mkIf (config.shell.tmux) {
          userPackages.shell = [
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
          })
          (lib.mkIf (config.shell.ranger) {

          userPackages.ranger = [
          (pkgs.symlinkJoin {
          name = "ranger";
          paths = [ pkgs.ranger ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
          wrapProgram $out/bin/ranger \
          --set RANGER_LOAD_DEFAULT_RC FALSE \
          --add-flags "--cmd='source ${rangerConf}'"
          '';
        })
      ];
    })
  ]);
}
