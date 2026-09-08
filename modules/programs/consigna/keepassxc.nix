{ pkgs, lib, config, ... }:
{
  options.keepassxc = {
    enable = lib.mkEnableOption "Activa cliente KeePassXC";
  };

  config = lib.mkIf config.keepassxc.enable {
    userPackages.seguridad = [ pkgs.keepassxc ];

    environment.etc."xdg/keepassxc/keepassxc.ini".text = ''
      [GUI]
      ApplicationTheme=dark

      [Security]
      LockDatabaseIdle=false
      LockDatabaseIdleSeconds=0
      LockDatabaseMinimize=false
      LockDatabaseScreenLock=false
      LockDatabaseOnUserSwitch=false

      [SSHAgent]
      Enabled=true
    '';

    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [{ directory = ".config/keepassxc"; mode = "0700"; }];
      };
  };
}
