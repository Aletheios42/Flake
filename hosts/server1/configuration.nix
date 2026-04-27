# hosts/server/configuration.nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ../../modules/features/ssh.nix
    ../../modules/core/boot.nix
    ../../modules/core/system.nix
    ../../modules/core/users.nix
  ];
}
