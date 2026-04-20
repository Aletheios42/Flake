{...}:
{
  networking = {
    hostName = "machine";
    nameservers = ["9.9.9.9" "1.1.1.1"];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 22];
    };
    networkmanager = {
      enable = true;
      dns = "none"; # evita que nm sobrescriba mis nameservers de dns de dns
    };
  };
  time.timeZone = "Europe/Madrid";
}
