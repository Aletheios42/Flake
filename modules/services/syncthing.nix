{ lib, config, ... }: {
  options.syncthing = {
    enable = lib.mkEnableOption "Activa systing";
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario que ejecuta synthing";
    };
    subdominio = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "usuario del dominio";
    };
  };
  config = lib.mkIf (config.syncthing.enable) {
    assertions = [{
      assertion = config.vars.dominio != "" && config.syncthing.subdominio != "";
      message = "Dominio y Subdominio son necesarios";
    }];
    services.syncthing = {
      enable = true;
      user = config.syncthing.usuario;
      dataDir = "/home/${config.syncthing.usuario}/sync";
      configDir = "/home/${config.syncthing.usuario}/.config/syncthing";
      openDefaultPorts = true;
      guiAddress = "127.0.0.1:8384";
    };
    services.nginx.virtualHosts."${config.syncthing.subdominio}.${config.vars.dominio}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8384";
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

    myImpermanence.users.${config.syncthing.usuario} = {
      directories = [
        "sync"
        ".config/syncthing"
      ];
    };
  };
}
