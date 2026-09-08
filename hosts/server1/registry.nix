#server1
[
  ../../modules/core/system.nix
  ../../modules/core/network.nix
  ../../modules/core/boot.nix
  ../../modules/core/documentacion.nix
  ../../modules/core/users.nix
  ../../modules/core/nix.nix
  ../../modules/core/virtualizacion.nix

  ../../modules/infra/sops.nix
  ../../modules/infra/ssh.nix
  ../../modules/infra/impermanence.nix
  ../../modules/infra/git.nix

  ../../modules/programs/nvim.nix
  ../../modules/programs/consigna/vaultwarden.nix
  ../../modules/programs/pkm.nix
  ../../modules/programs/shell/zsh.nix
  ../../modules/programs/shell/ranger.nix
  ../../modules/programs/shell/kitty.nix
  ../../modules/programs/shell/tmux.nix
  ../../modules/programs/shell/direnv.nix
  ../../modules/programs/shell/kmscon.nix

  ../../modules/services/cf-ddns.nix
  ../../modules/services/postgresql.nix
  ../../modules/services/nginx.nix
  ../../modules/services/mailserver.nix
  ../../modules/services/auth/oauth2proxy.nix
  ../../modules/services/firefly.nix
  ../../modules/services/forgejo.nix
  ../../modules/services/monitoring.nix
  ../../modules/services/nextcloud.nix
  ../../modules/services/syncthing.nix
  ../../modules/services/miniflux.nix
  ../../modules/services/vpn/headscale.nix
  ../../modules/services/vpn/tailscale.nix
  ../../modules/services/media/jellyfin.nix
  ../../modules/services/media/immich.nix

  ../../modules/services/mis_webs/europa_nos_une.nix
]
