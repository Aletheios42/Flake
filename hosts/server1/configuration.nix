{ pkgs, config, ... }:
{
  imports = [
    ../../modules/default.nix
    ./hardware-configuration.nix
    ./disk.nix
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
    secretsFile = ../../secrets/server1.yaml;
    useSshKey = true;
  };

  arranque = {
    enable = true;
    loader = "monolito";
  };

  red = {
    enable = true;
    hostname = "server1";
    firewall = true;
    puertosPermitidos = [ 80 443 25 143 465 587 993 ];
    timeZone = "Europe/Madrid";
  };

  sistema.enable = true;
  sistema.version = "26.05";

  usuarios = {
    aletheios42 = {
      hashedPassword = "$6$p7IwCtyd.a9aWxQ7$7curRU6NV9aUqMq4h7T0814y5jSPDDcrJpvBiLPADtnrc.kHPv8P2FsUQ06oAw1/hriWmQgoKujDQkhBV.3II1";
      llavesSsh = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIUIAwasvm3HzuviTRGOOwXq9N3+h77+LOf9nA5AFtdP Machine" ];
      grupos = [ "wheel" "networkmanager" "video" "input" "audio" "docker" "uucp" "dialout" "libvirtd" ];
      shell = pkgs.zsh;
    };
  };

  nginx = {
    enable = true;
    email = "admin@alejandropintosalcarazo.com";
  };

  mi_mailserver = {
    enable = true;
    accounts = {
      "admin@alejandropintosalcarazo.com" = {
        hashedPasswordFile = config.sops.secrets."mailserver/admin_pass".path;
        aliases = [ "postmaster@alejandropintosalcarazo.com" ];
      };
    };
  };

  monitoring = {
    enable = true;
    subdominio = "observe";
    port = 5080;
  };

  firefly = {
    enable = true;
    subdominio = "presupuesto";
    usuario = "aletheios42";
  };

  vpn = {
    enable = true;
    usuario = "aletheios42";
    subdominio = "vpn";
  };

  shell = {
    enable = true;
    zsh = true;
    ranger = true;
    kitty = false;
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

  virtualizacion = {
    enable = true;
    docker = true;
    podman = false;
    qemu = false;
  };

  git = {
    enable = true;
    name = "aletheios42";
  };

  pantalla.enable = true;

  media= {
    enable = true;
    musica = {
      enable = true;
      subdominio = "jellyfin";
    };
    galeria = {
      enable = true;
      subdominio = "fotos";
    };
    obs.enable = false;
  };

  passwords = {
    enable = true;
    vaultwarden = {
      enable = true;
      subdominio = "vaultwarden";
    };
  };

  syncthing = {
    enable = true;
    usuario = "aletheios42";
    subdominio = "syncthing";
  };

  forgejo = {
    enable = true;
    subdominio = "git";
  };

  nextcloud = {
    enable = true;
    usuario = "aletheios42";
    subdominio = "cloud";
  };

  rss = {
    enable = true;
    subdominio = "rss";
  };

}
