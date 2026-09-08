{ pkgs, ... }:
{
  imports = (import ./registry.nix) ++ [
    ./hardware-configuration.nix
    ./disk.nix
  ];

  sistema.enable = true;

  impermanencia = {
    enable = true;
    dispositivo = "/dev/mapper/crypted";
  };

  sops = {
    enable = true;
    secretsFile = ../../secrets/server1.yaml;
    useSshKey = true;
  };

  arranque = {
    enable = true;
    loader = "monolito";
  };

  cf-ddns.enable = true;
  red = {
    enable = true;
    hostname = "server1";
    firewall = true;
    puertosPermitidos = [ 80 443 25 143 465 587 993 995];
    timeZone = "Europe/Madrid";
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

  virtualizacion = {
    enable = true;
    docker = true;
    podman = true;
    qemu = false;
  };

  git = {
    enable = true;
    name = "aletheios42";
  };

  postgres = {
    enable = true;
    puerto = 5432;
    subdominio = "postgres";
    pgadmin.puerto = 5050;
    pgbouncer.puerto = 6432;
    databases = [ "test" ];
    datalocation = "/var/backup/postgresql";
  };

  nginx = {
    enable = true;
    email = "admin@alejandropintosalcarazo.com";
  };

  correo = {
    enable = true;
    fqdn = "mail.alejandropintosalcarazo.com";
    dominios = [ "alejandropintosalcarazo.com" ];
    accounts."contacto@alejandropintosalcarazo.com" = {
      hashedPassword = "$y$j9T$k0R3CJvL4c.7tMoIJnduc1$9asLr/JUGCYRdQyeRoxKGfB2dPRFYQ0xsX0gIdWD9b2";
      aliases = [
        "postmaster@alejandropintosalcarazo.com"
        "@alejandropintosalcarazo.com" # Atrapa todo lo demás
      ];
      sieveScript = ''
        require ["fileinto", "mailbox", "subaddress", "regex", "variables"];

        # 1. Tu buzón principal va al Inbox
        if address :is "to" ["contacto@alejandropintosalcarazo.com", "postmaster@alejandropintosalcarazo.com"] {
          keep;
          stop;
        }

        # 2. Todo lo que lleve punto va a su categoría (ej. sub.noticias@... -> Categorias/sub)
        if address :regex :user "to" "^([a-zA-Z0-9_-]+)\\..*$" {
          fileinto :create "Categorias/''${1}";
          stop;
        }

        # 3. Fallback con '+' (contacto+algo@... -> Tags/algo)
        if address :matches :detail "to" "*" {
          fileinto :create "Tags/''${1}";
          stop;
        }
      '';
    };
  };

  # meter netbird
  # vpn = {
  #   enable = false;
  #   usuario = "aletheios42";
  #   subdominio = "vpn";
  # };

  monitoring = {
    enable = false;
    subdominio = "openobserve";
    port = 5080;
  };

  firefly = {
    enable = false;
    subdominio = "firefly";
    usuario = "aletheios42";
  };

  media = {
    musica = {
      enable = false;
      subdominio = "jellyfin";
    };
    galeria = {
      enable = false;
      subdominio = "fotos";
    };
  };

  vaultwarden = {
    enable = true;
    subdominio = "vaultwarden";
  };

  syncthing = {
    enable = false;
    usuario = "aletheios42";
    subdominio = "syncthing";
  };

  forgejo = {
    enable = false;
    subdominio = "git";
  };

  nextcloud = {
    enable = false;
    usuario = "aletheios42";
    subdominio = "cloud";
  };

  miniflux = {
    enable = true;
    subdominio = "miniflux";
    puerto = 8080;
  };

  
  # webs.europaNosUne = {
  #   enable = true;
  #   gitUrl = "https://github.com/Aletheios42/NewsPaper";
  #   subdominio = "europanosune";
  #   puertoDirectus = 8055;
  #   puertoFrontend = 3000;
  #   WorkingDirectory = "/opt/europanosune/";
  # };
}
