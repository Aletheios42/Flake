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
      hashedPasswordFile = config.sops.secrets."users/aletheios42_password".path;
      llavesSsh = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFwPpoIGjOdnehdg/bI3KVsdirAUygqJOoyiK301W2h0 aletheios42" ];
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

  zitadel = {
    enable = true;
    subdominio = "auth";
  };

  oauth2proxy.enable = true;

  homepage = {
    enable = true;
    subdominio = "home";
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
    podman = true;
    qemu = true;
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
    obs.enable = true;
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
