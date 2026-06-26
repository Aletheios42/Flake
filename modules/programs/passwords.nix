{ pkgs, lib, config, ... }:
{
  options.passwords = {
    enable = lib.mkEnableOption "Gestion de mis contaseñas";
    keepassxc = lib.mkOption {
      type = lib.types.bool;
      description = "Activa keepassxc";
      default = false;
    };
    vaultwarden = {
      enable = lib.mkEnableOption "activar el servidor de contraseñas vaulwrden";
      subdominio = lib.mkOption {
        type = lib.types.str;
        description = "subdominio asociado a tu servidor";
      };
    };
  };

  config = lib.mkIf (config.passwords.enable) (lib.mkMerge [
    {
      assertions = [{
        assertion = config.passwords.keepassxc || config.passwords.vaultwarden.enable;
        message = "Activa keepass o vaultwarden";
      }];
    }

    (lib.mkIf (config.passwords.keepassxc) {
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
      myImpermanence.users.${config.vars.usuarioPrincipal} = {
        directories = [ ".config/keepassxc" ];
      };
    })

    (lib.mkIf (config.passwords.vaultwarden.enable) {
      services.vaultwarden = {
        enable = true;
        config = {
          DOMAIN = "https://${config.passwords.vaultwarden.subdominio}.${config.vars.dominio}";
          SIGNUPS_ALLOWED = false;
          ROCKET_PORT = 8222;
        };
      };
      services.nginx.virtualHosts."${config.passwords.vaultwarden.subdominio}.${config.vars.dominio}" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8222";
          proxyWebsockets = true;
          extraConfig = lib.optionalString config.oauth2proxy.enable ''
            auth_request /oauth2/auth;
            error_page 401 = /oauth2/sign_in;
          '';
        };
        locations."/oauth2/" = lib.mkIf config.oauth2proxy.enable {
          proxyPass = "http://127.0.0.1:4180";
          extraConfig = ''
            proxy_set_header X-Scheme $scheme;
            proxy_set_header X-Auth-Request-Redirect $request_uri;
            proxy_set_header Host $host;
          '';
        };
      };

      myImpermanence.system.directories = [ "/var/lib/vaultwarden" ];
    })
  ]);
}
