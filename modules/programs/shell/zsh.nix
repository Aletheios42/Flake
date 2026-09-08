{ pkgs, lib, config, ... }:
let
  zshPreamble = ''
    zstyle ':completion:*' menu no
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zcompcache
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

    export SAVEHIST=100000
    setopt SHARE_HISTORY HIST_IGNORE_DUPS
    export FZF_DEFAULT_COMMAND="rg --files --hidden --smart-case"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden"
    export FZF_DEFAULT_OPTS="--layout=reverse --border --height=40% --preview 'bat --style=numbers --color=always {}' --preview-window=right:50%"

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
  '' + lib.optionalString config.pkm.zk ''
  pkm() { cd "$ZK_NOTEBOOK_DIR" && nvim; }
'';

  zshBindings = ''
    eval "$(fzf --zsh)"
    bindkey "^[r" alt-r-widget
  '';
in
{
  options.shell.zsh = lib.mkOption { type = lib.types.bool; default = true; description = "activa zsh"; };

  config = lib.mkIf config.shell.zsh {
    userPackages.shell = [ pkgs.ripgrep pkgs.tree pkgs.fd pkgs.fzf pkgs.bat pkgs.lsd ];
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      histSize = 100000;
      histFile = "$HOME/.zsh_history";
      ohMyZsh = { enable = true; plugins = [ "git" "docker" "sudo" ]; theme = "robbyrussell"; };
      interactiveShellInit = zshPreamble
        + lib.optionalString (config.shell.direnv) ''eval "$(direnv hook zsh)"
        '';
    };
    environment.etc."zshrc.local".text = zshBindings;
    system.activationScripts.zshrc-user = ''
      PERSIST_TARGET="/persist/home/${config.usuarioPrincipal}/.zshrc"
      if [ -L "/home/${config.usuarioPrincipal}/.zshrc" ] && [ -r "$PERSIST_TARGET" ]; then
        echo 'source /etc/zshrc' > "$PERSIST_TARGET"
      elif [ ! -f "/home/${config.usuarioPrincipal}/.zshrc" ]; then
        echo 'source /etc/zshrc' > "/home/${config.usuarioPrincipal}/.zshrc"
        chown ${config.usuarioPrincipal}:users "/home/${config.usuarioPrincipal}/.zshrc"
      fi
    '';
    environment.persistence."/persist".users.${config.usuarioPrincipal} = {
      directories = [ { directory = ".zcompcache"; mode = "0755"; } ];
      files = [
        { file = ".zshrc"; }
        { file = ".zsh_history"; }
      ];
    };
  };
}
