{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../../modules/default.nix
  ];

  vars = {
    dominio = "alejandropintosalcarazo.com";
  };

  impermanencia = {
    enable = true;
    dispositivo = "/dev/mapper/crypted";
  };

  sistema.enable = true;
  arranque = {
    enable = true;
    loader = "monolito";
  };
  red = {
    enable = true;
    hostname = "machine";
    timeZone = "Europe/Madrid";
    puertosPermitidos = [ 80 443 8621 8889 8890 11111 ];
  };

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
    sway = true;
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

  media = {
    enable = true;
    cliente = true;
    obs.enable = true;
  };

  obsidian.enable = true;

  passwords = {
    enable = true;
    keepassxc = true;
  };

  comunicacion = {
    enable = true;
    discord = true;
    whatsie = true;
    slack = true;
    telegram = true;
    thunderbird = true;
    weechat = true;
    element = true;
  };
  navegadores = {
    enable = true;
    librewolf = true;
    chromiun = true;
    tor = true;
    qutebrowser = true;
  };

  lectura = {
    enable = true;
    zathura = true;
    calibre = true;
    koreader = true;
  };

  android.enable = true;
}
