{ ... }:
{
  services.openssh = {
    enable = true;
    ports = [ 1234 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };
  programs.ssh.startAgent = true;
}
