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
  # Configuración zsh: fzf + alt-r widget. Pertenece al bloque zsh, no al de direnv.
  zshConf = ''
    zstyle ':completion:*' menu no
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zcompcache
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

    # fzf shell integration (requiere shell.cli para tener fzf/rg/fd)
    eval "$(fzf --zsh)"

    export FZF_DEFAULT_COMMAND="rg --files --hidden --smart-case"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden"
    export FZF_DEFAULT_OPTS="--layout=reverse --border --height=40% --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%"

    # Alt+R: buscar por contenido, insertar path en prompt
    alt-r-widget() {
      local result
      result=$(
        rg --column --color=always --smart-case "" 2>/dev/null \
        | fzf --disabled --ansi \
              --bind "change:reload:rg --column --color=always --smart-case {q} || :" \
              --delimiter : \
              --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
              --preview-window 'right:50%' \
        | cut -d: -f1
      )
      [[ -n "$result" ]] && LBUFFER+="$result"
      zle redisplay
    }
    zle -N alt-r-widget
    bindkey "^[r" alt-r-widget
  '';
  # ranger: config personalizada. El RC por defecto se carga primero (vim keybindings incluidos).
  rangerConf = pkgs.writeText "rc.conf" ''
    set show_hidden true
    set preview_images true
    set preview_images_method w3m
    map f shell find . -name "%s"
    map yy copy
    map dd cut
    map pp paste
  '';
  treeCat = pkgs.writeShellApplication {
    name = "tree-cat";
    runtimeInputs = [ pkgs.tree pkgs.fd pkgs.wl-clipboard ];
    text = builtins.readFile ../scripts/tree-cat.sh;
  };
  rfv = pkgs.writeShellApplication {
    name = "rfv";
    runtimeInputs = [ pkgs.fzf pkgs.ripgrep pkgs.bat pkgs.neovim ];
    text = builtins.readFile ../scripts/rfv.sh;
  };
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
      description = "activa zsh";
    };
    ranger = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa ranger";
    };
    cli = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa herramientas cli";
    };
    tmux = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa tmux";
    };
    direnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "activa direnv con nix-direnv";
    };
  };

  config = lib.mkIf config.shell.enable (lib.mkMerge [
    {
      assertions = [{
        assertion = config.shell.kitty || config.shell.zsh || config.shell.ranger || config.shell.cli || config.shell.tmux;
        message = "Debes activar al menos una herramienta de shell";
      }];
      userPackages.scripts = [ treeCat rfv ];
    }
    {
      environment.variables.TERM = "xterm-256color";
    }

    (lib.mkIf config.shell.kitty {
      userPackages.kitty = [
        (pkgs.symlinkJoin {
          name = "kitty";
          paths = [ pkgs.kitty ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/kitty \
              --add-flags "--config ${kittyConf}"
          '';
        })
      ];
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/kitty" ];
      };
    })

    (lib.mkIf config.shell.cli {
      userPackages.shell = [ pkgs.ripgrep pkgs.tree pkgs.fd pkgs.fzf pkgs.bat pkgs.lsd ];
    })

    (lib.mkIf config.shell.zsh {
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
        # zshConf pertenece aquí, no en el bloque direnv
        interactiveShellInit = zshConf;
      };
    })

    (lib.mkIf config.shell.tmux {
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
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/tmux" ];
      };
    })

    (lib.mkIf config.shell.ranger {
      userPackages.ranger = [
        (pkgs.symlinkJoin {
          name = "ranger";
          paths = [ pkgs.ranger ];
          buildInputs = [ pkgs.makeWrapper ];
          # No se deshabilita el RC por defecto — preserva todos los vim keybindings nativos.
          # La config personalizada se añade encima.
          postBuild = ''
            wrapProgram $out/bin/ranger \
              --add-flags "--cmd='source ${rangerConf}'"
          '';
        })
      ];
    })

    (lib.mkIf config.shell.direnv {
      userPackages.direnv = [ pkgs.direnv pkgs.nix-direnv ];
      # Solo el hook de direnv aquí; zshConf ya está en el bloque zsh
      programs.zsh.interactiveShellInit = ''eval "$(direnv hook zsh)"'';
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/direnv" ];
      };
    })

  ]);
}
