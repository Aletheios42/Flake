# hosts/server/configuration.nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./ssh.nix
    ../../modules/services/tailscale.nix
    ../../modules/core/boot.nix
    ../../modules/core/system.nix
    ../../modules/core/users.nix
  ];
}
