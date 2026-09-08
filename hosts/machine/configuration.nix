{ pkgs, ... }:
{
imports = (import ./registry.nix) ++ [
  ./hardware-configuration.nix
  ./disk.nix
];

  userPackages.scripts = [
    (import ../../modules/scripts/rfv.nix { inherit pkgs; })
    (import ../../modules/scripts/tree-cat.nix { inherit pkgs; })
  ];
  # hacer serccion de paquetes de dev
  userPackages.dev = [ pkgs.gnumake pkgs.gdb pkgs.gcc pkgs.magic-wormhole-rs ];

  sistema.enable = true;

  impermanencia = {
    enable = true;
    dispositivo = "/dev/mapper/crypted";
  };

  sops = {
    enable = true;
    secretsFile = ../../secrets/machine.yaml;
    useSshKey = true;
  };

  arranque = {
    enable = true;
    loader = "monolito";
  };

  red = {
    enable = true;
    hostname = "machine";
    timeZone = "Europe/Madrid";
    puertosPermitidos = [ 80 443 8621 8889 8890 ];
    dominio = "alejandropintosalcarazo.com";
  };

  usuarioPrincipal = "aletheios42";
  usuarios = {
    aletheios42 = {
      hashedPassword = "$6$p7IwCtyd.a9aWxQ7$7curRU6NV9aUqMq4h7T0814y5jSPDDcrJpvBiLPADtnrc.kHPv8P2FsUQ06oAw1/hriWmQgoKujDQkhBV.3II1";
      llavesSsh = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpmfb5bZFHDK6zE2cnLWkGJPiSq8lxpSGhOkHKNIxVP Admin" ];
      grupos = [ "wheel" "networkmanager" "video" "input" "audio" "docker" "uucp" "dialout" "libvirtd" ];
      shell = pkgs.zsh;
    };
  };

  ai =  {
    opencode.enable = true;
    opendesign.enable = true;
    opendesign.puerto = 7457;
    litellm.enable = true;
    litellm.puerto = 4000;
  };

  shell = {
    zsh = true;
    ranger = true;
    kitty = true;
    tmux = true;
    direnv = false;
    kmscon = false;
  };

  editor.enable = true;

  ssh = {
    enable = true;
    cliente.enable = true;
    servidor = {
      enable = true;
      puertos = [1234];
    };
  };

  escritorio = {
    enable = true;
    mango = true;
    sway = true;
    # niri = true;
    noctalia = true;
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

  bluetooth.enable = true;
  audio.enable = true;
  media.cliente = true;

  pkm = {
    enable = true;
    dir = "/home/aletheios42/Documentos/Pkm/";
    zk = true;
    obsidian = false;
  };

  comunicacion = {
    cliente = true;
    thunderbird = true;
  };

  navegadores = {
    firefox.enable = true;
    chromium.enable = true;
    qutebrowser.enable = true;
    tor.enable = true;
  };

  lectura = {
    zathura = true;
    calibre = true;
    koreader = true;
  };

  android.enable = true;
  labctl.enable = true;
  vpn.tailscale.enable = true;
  rbw.enable = true;
}
