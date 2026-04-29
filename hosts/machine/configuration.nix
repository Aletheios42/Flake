{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  vars = {
    dominio = "alejandropintosalcarazo.com";
  };

  sistema.enable = true;
  arranque = {
    enable = true;
    loader = "dual-boot";
  };
  red = {
    enable = true;
    hostname = "machine";
    timeZone = "Europe/Madrid";
  };

  # nginx = {
  #   enable = true;
  #   email = "admin@alejandropintosalcarazo.com";
  # };

  # vpn = {
  #   enable = true;
  #   usuario = "aletheios42";
  #   subdominio = "vpn";
  # };

  usuarios = {
    aletheios42 = {
      hashedPassword = "$y$j9T$xJH0zJRapD/u6RqPiYYkV1$UCRHx50IP/6T2.6CQr5VLGBVakzrQn5plcgUayvLOF1";
      llavesSsh = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBNAFtwsoBJcft2fw5ds2h0QnShb9osnxWVyMsBnClH aletheios42" ];
      grupos = [ "wheel" "networkmanager" "video" "input" "audio" "docker" "uucp" "dialout" "libvirtd" ];
      shell = pkgs.zsh;
    };
  };

  shell = {
    enable = true;
    zsh = true;
    ranger = true;
    kitty = true;
    cli = true;
    tmux = true;
    direnv = true;
  };
  editor.enable = true;

  mi_ssh = {
    enable = true;
    cliente.enable = true;
    servidor = {
      enable = true;
      puertos = [1234];
    };
  };

  escritorio = {
    enable = true;
    tailing = "sway";
  };

  virtualizacion = {
    enable = true;
    docker = true;
    podman = true;
    qemu = true;
  };

  git = {
    enable = true;
    name = "aletheios42";
    email = "";
  };

  documentacion.enable = true;

  bluetooth.enable = true;
  audio.enable = true;
  pantalla.enable = true;

  media= {
    enable = true;
    cliente = true;
    # musica = {
    #   enable = true;
    #   subdominio = "jellyfin";
    # };
    # galeria = {
    #   enable = true;
    #   subdominio = "fotos";
    # };
    obs.enable = true;
  };

  obsidian.enable = true;

  passwords = {
    keepassxc = true;
    # vaultwarden = {
    #   enable = true;
    #   subdominio = "vaultwarden";
    # };
  };

  comunicacion.enable = true;
  navegadores = {
    enable = true;
    librewolf = true;
    google-chrome = true;
    qutebrowser = true;
  };

  ## quitar para machine
#   syncthing = {
#     enable = true;
#     usuario = "aletheios42";
#     subdominio = "syncthing";
#   };
#
#   forgejo = {
#     enable = true;
#     subdominio = "git";
#   };
#
#   nextcloud = {
#     enable = true;
#     usuario = "aletheios42";
#     subdominio = "cloud";
#   };
  # firefly = {
  #   enable = true;
  #   subdominio = "presupuesto";
  #   usuario = "aletheios42";
  # };
}
