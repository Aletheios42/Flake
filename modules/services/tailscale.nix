{ pkgs, ... }:
{
  services.tailscale.enable = true;
  environment.systemPackages = [ pkgs.tailscale ];
  # Tras el primer boot: sudo tailscale up
}
