{ pkgs, lib, config, ... }:
let
  kittyConf = pkgs.writeText "kitty.conf" ''
    scrollback_lines -1
    enable_audio_bell no
    confirm_os_window_close 0
    map shift+enter send_text all \n
  '';
  tmuxConf = pkgs.writeText "tmux.conf" ''
    set -g clock-mode-style 24
    set -sg escape-time 10
    set -g base-index 1
    set -g pane-base-index 1

    # Plugins (cargados via nix, no TPM)
    set -g @resurrect-dir '~/.local/share/tmux/resurrect'
    run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '15'
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
    run-shell ${pkgs.tmuxPlugins.vim-tmux-navigator}/share/tmux-plugins/vim-tmux-navigator/vim-tmux-navigator.tmux
  '';
  # Antes de oh-my-zsh (plugins, funciones, variables de entorno)
  zshPreamble = ''
    zstyle ':completion:*' menu no
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zcompcache
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

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
  '';

  # Despues de oh-my-zsh (keybindings, se sobreescriben si van antes)
  zshBindings = ''
    eval "$(fzf --zsh)"
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
        interactiveShellInit = zshPreamble
          + lib.optionalString config.shell.direnv ''eval "$(direnv hook zsh)"
'';
      };
      # Se sourcea al final de /etc/zshrc, despues de oh-my-zsh
      environment.etc."zshrc.local".text = zshBindings;
      # Crea ~/.zshrc que sourcea el /etc/zshrc global de NixOS
      system.activationScripts.zshrc-user = ''
        PERSIST_TARGET="/persist/home/${config.vars.usuarioPrincipal}/.zshrc"
        if [ -L "/home/${config.vars.usuarioPrincipal}/.zshrc" ] && [ -r "$PERSIST_TARGET" ]; then
          # impermanence: escribir directamente al target del symlink
          echo 'source /etc/zshrc' > "$PERSIST_TARGET"
        elif [ ! -f "/home/${config.vars.usuarioPrincipal}/.zshrc" ]; then
          echo 'source /etc/zshrc' > "/home/${config.vars.usuarioPrincipal}/.zshrc"
          chown ${config.vars.usuarioPrincipal}:users "/home/${config.vars.usuarioPrincipal}/.zshrc"
        fi
      '';
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        files = [ ".zshrc" ];
        directories = [ ".zcompcache" ];
      };
    })

    (lib.mkIf config.shell.tmux {
      userPackages.tmux = [
        (pkgs.symlinkJoin {
          name = "tmux";
          paths = [ pkgs.tmux ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/tmux \
              --add-flags "-f ${tmuxConf}"
          '';
        })
      ];
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/tmux" ".local/share/tmux" ];
      };
    })

    (lib.mkIf config.shell.ranger {
      userPackages.ranger = [
        (pkgs.symlinkJoin {
          name = "ranger";
          paths = [ pkgs.ranger ];
          buildInputs = [ pkgs.makeWrapper ];
          # No se deshabilita el RC por defecto — preserva todos los vim keybindings nativos.
          # La config personalizada se anade encima.
          postBuild = ''
            wrapProgram $out/bin/ranger \
              --add-flags "--cmd='source ${rangerConf}'"
          '';
        })
      ];
    })

    (lib.mkIf config.shell.direnv {
      userPackages.direnv = [ pkgs.direnv pkgs.nix-direnv ];
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/direnv" ];
      };
    })

  ]);
}
