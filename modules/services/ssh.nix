{...}:
{
  programs.ssh.startAgent = true;
  boot.initrd.network.ssh.enable = true;
  boot.initrd.network.ssh.port = 1234;
}

