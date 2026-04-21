{ config, lib, pkgs, ... }:
{
  options.userPackages = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.package);
    default = {};
  };

  config = {
    programs.zsh.enable = true;
    users.mutableUsers = false;
    users.users.aletheios42 = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKBNAFtwsoBJcft2fw5ds2h0QnShb9osnxWVyMsBnClH aletheios42"
      ];
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "video" "input" "audio" "docker" "uucp" "dialout" "libvirtd" ];
      shell = pkgs.zsh;
      hashedPassword ="$y$j9T$xJH0zJRapD/u6RqPiYYkV1$UCRHx50IP/6T2.6CQr5VLGBVakzrQn5plcgUayvLOF1";
      packages = lib.flatten (lib.attrValues config.userPackages);
    };
  };
}
