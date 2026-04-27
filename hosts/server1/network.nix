{ ... }:
{
  networking = {
    hostName = "server1";
    nameservers = [ "9.9.9.9" "1.1.1.1" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ 41641 ]; # tailscale
    };
    networkmanager.enable = true;
  };
  time.timeZone = "Europe/Madrid";
}
