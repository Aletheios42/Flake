{ ... }:
{
  services.openssh = {
    enable = true;
    ports = [ 1234 ];
    
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password"; # Mejor que "no" si usas deploy-rs o colmena
      
      ClientAliveInterval = 120;
      ClientAliveCountMax = 3;
    };

    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host *
        ForwardAgent yes
        AddKeysToAgent yes
    '';
  };

  networking.firewall.allowedTCPPorts = [ 1234 ];

  users.users.aletheios42.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBNAFtwsoBJcft2fw5ds2h0QnShb9osnxWVyMsBnClH aletheios42"
  ];
}
