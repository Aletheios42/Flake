{ pkgs, config, ... }:
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

  mi_sops = {
    enable = true;
    secretsFile = ../../secrets/machine.yaml;
    useSshKey = false;
  };

  sistema.enable = true;
  sistema.version = "26.05";
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
      hashedPasswordFile = config.sops.secrets."users/aletheios42_password".path;
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
  };

  documentacion.enable = true;

  ai = {
    enable = true;
    opencode = {
      enable       = true;
      engram.enable  = true;
      context7.enable = true;
      squeez.enable  = true;
    };
    llama = {
      enable = true;
      serve  = true;
    };
    whisper.enable = true;
  };

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
    firefox = true;
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
