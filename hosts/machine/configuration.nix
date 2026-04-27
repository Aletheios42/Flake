{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];
  bluetooth.enable = true;
  audio.enable = true;
  arranque.enable = true;
  pantalla.enable = true;
  direnv.enable = true;
  git = {
    enable = true;
    name = "aletheios42";
    email = "";
  };
  media.enable = true;
  obs.enable = true;
  obsidian.enable = true;
  passwords.enable = true;
  escritorio = {
    enable = true;
    tailing = "sway";
  };
  virtualizacion = {
    enable = true;
    docker = true;
    podman = true;
    libvirtd = true;
  };
  comunicacion.enable = true;
  navegadores = {
    enable = true;
    librewolf = true;
    google-chrome = true;
    qutebrowser = true;
  };
  editor.enable = true;
  shell.enable = true;
}
