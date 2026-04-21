{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/system.nix
    ../../modules/core/boot.nix
    ../../modules/core/display.nix
    ../../modules/core/network.nix
    ../../modules/core/system-packages.nix
    ../../modules/core/users.nix
    ../../modules/core/virtualization.nix
    ../../modules/apps/scripts/scripts.nix
    ../../modules/apps/passwords.nix
    ../../modules/apps/comunicacion.nix
    ../../modules/apps/direnv.nix
    ../../modules/apps/fzf.nix
    ../../modules/apps/git.nix
    ../../modules/apps/kitty.nix
    ../../modules/apps/media.nix
    ../../modules/apps/navegadores.nix
    ../../modules/apps/niri.nix
    ../../modules/apps/nvim.nix
    ../../modules/apps/obs.nix
    ../../modules/apps/ranger.nix
    ../../modules/apps/scripts/scripts.nix
    ../../modules/apps/shell.nix
    ../../modules/apps/sway.nix
    ../../modules/apps/tmux.nix
    ../../modules/apps/zsh.nix
    ../../modules/services/audio.nix
    ../../modules/services/bluetooth.nix
    ../../modules/services/ssh.nix
    ../../modules/services/tailscale.nix
  ];
}

