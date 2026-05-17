{ lib, config, ... }: {
  options.syncthing = {
    enable = lib.mkEnableOption "Activa systing";
    usuario = lib.mkOption {
      type = lib.types.str;
      description = "usuario que ejecuta synthing";
    };
    subdominio = lib.mkOption {
      type = lib.types.str;
      description = "usuario del dominio";
    };
  };
  config = lib.mkIf (config.syncthing.enable) {
    assertions = [{
      # interesante poner como assertion pong a [localhost](http://localhost) :80 :443
      assertion = config.vars.dominio != "" && config.syncthing.subdominio != ""; ## Subdominio redundante porque no hay default pero bueno.
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
      };
    };
  };
}
