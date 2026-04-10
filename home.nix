{ config, lib, pkgs, inputs, ... }:

let
  scripts = import ./scripts/default.nix { inherit pkgs carpeta_grabaciones carpeta_pantallazo; };
  mod = "Mod4";
  terminal = "kitty";
  user = "aletheios42";
  carpeta_musica = "Comunes/Música";
  carpeta_grabaciones = "Comunes/Videos/Grabaciones";
  carpeta_pantallazo = "Comunes/Imagenes/Pantallazos";
  dagger = pkgs.stdenv.mkDerivation rec {
    name = "dagger";
    version = "0.20.1";
    src = pkgs.fetchurl {
      url = "https://dl.dagger.io/dagger/releases/${version}/dagger_v${version}_linux_amd64.tar.gz";
      sha256 = "sha256-ASr6gZqdRZOJrzTxBVwGTcEXiBCAv5HcMaa0aU8rz5k=";
    };
    dontUnpack = true;
    installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin dagger
    chmod +x $out/bin/dagger
    '';
  };
in
  {
  imports = [ ./i3.nix ./sway.nix ./nvim.nix  inputs.nvf.homeManagerModules.default ];

  home.username = user;
  home.homeDirectory = "/home/aletheios42";
  home.stateVersion = "25.11";
  manual.manpages.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # --- nh ---
  # Docs: https://home-manager-options.extranix.com/?query=nh&release=release-25.11
  programs.nh = {
    enable = true;
    #clean.dates = "ya veremos";
  };
    

  # --- SSH ---
  services.ssh-agent.enable = true;
  # --- PAQUETERÍA ---
  home.packages = with pkgs; [

    # Teclado
    wev xev

    # GUI Básica
    kitty rofi dmenu lxappearance swaylock i3lock

    # Navegadores
    firefox google-chrome chromium brave qutebrowser

    # Brillo
    brightnessctl

    # Multimedia
    musikcube # Reproductor de música
    pavucontrol # Para controlar el volumen gráficamente
    vlc mpv ffmpeg-full # Reproductor de video
    grim slurp # screenshots en Sway
    wf-recorder # Grabar pantalla en sway
    maim slop # screenshots en i3
    simplescreenrecorder # Grabar pantalla en i3

    # Portapapeles
    wl-clipboard # Wayland
    xclip xsel # Xorg

    # Social
    discord slack thunderbird element-desktop

    # Seguridad
    keepassxc

    # Dev Tools C/C++ & Debug
    gcc gnumake cmake
    gdb valgrind
    clang-tools # Incluye clangd, clang-format
    compiledb # Genera compile_commands.json para LSP

    # Notas
    obsidian

    # Redes
    ethtool dnsutils net-tools fping

    # Emulacion
    qemu virt-manager

    # Utils
    # no se si tengo que hacer algo extra con pancdoc
    pandoc texlive.combined.scheme-medium
    ripgrep fd bat
    tree
    perf
    direnv
    zip unzip

    # Scripts
    scripts.tree-cat
    scripts.screenshot-x11
    scripts.toggle-record-x11
    scripts.screenshot-wayland
    scripts.toggle-record-wayland
  ];

  # zathura
  programs.zathura = {
    enable = true;
    extraConfig = ''
      # Definir color de fondo y texto (modo oscuro)
      set recolor true
      set recolor-keephue true
      set default-bg "#282828"  # Fondo oscuro
      set default-fg "#ebdbb2"  # Texto en color claro

      # Sincronizar clipboard
      set selection-clipboard clipboard
    '';
  };

  # Ranger

  programs.ranger = {
    enable = true;
    extraConfig = ''
      # Para ver archivos ocultos
      set show_hidden true

      #Para rastrear archivos
      map f shell find . -name "%s"

      # Para habilitar el preview
      set preview_images true
      set preview_images_method w3m

      # Para arreglar el copy-paste
      map yy copy
      map dd cut
      map pp paste
    '';
  };

  # fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Se conecta con tu Zsh automáticamente

    # Esto hace que fzf use ripgrep (rg) para buscar archivos.
    # Es mucho más rápido y respeta el .gitignore
    defaultCommand = "rg --files --hidden --glob '!.git/*'";
  };

  # Tmux
  programs.tmux = {
    enable = true;
    clock24 = true;
    extraConfig = ''
        set -sg escape-time 10
    '';
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
  };

  # Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git" "docker" "sudo"
      ];
      theme = "robbyrussell";
    };
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
    initContent = ''
        zstyle ':completion:*' menu no
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zcompcache
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';
  };

  # Kitty
  programs.kitty = {
    enable = true;
    settings = {
      enable_audio_bell = false;
    };
  };

  # Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "aletheios42";
        email = "";
      };
      init.defaultBranch = "master";
      credential.helper = "store";
    };
  };

  # OBS
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vkcapture
      input-overlay
    ];
  };

  # Thunderbird
  programs.thunderbird = {
    enable = true;

    profiles."aletheios42" = {
      isDefault = true;

      settings = {
        # Abrir mensajes en una nueva pestaña
        "mail.openMessageBehavior" = 2;

        # Opcional: Desactiva el panel de vista previa (F8) para que al hacer
        # clic tengas que hacer doble clic para abrir en la pestaña
        "mail.pane_config.dynamic" = 0;

        # --- MODO OSCURO ---
        # Le dice al navegador interno que use el modo oscuro
        "browser.in-content.dark-mode" = true;
        # Fuerza a la UI a pensar que el sistema está en modo oscuro
        "ui.systemUsesDarkTheme" = 1;
        # Activa el tema oscuro por defecto
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
      };
    };
  };
}
