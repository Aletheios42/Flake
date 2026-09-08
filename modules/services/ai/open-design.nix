{ lib, config, open-design, ... }:
{
  imports = [ open-design.nixosModules.default ];

  options.ai.opendesign = {
    enable = lib.mkEnableOption "Open Design daemon (MCP server para OpenCode)";
    puerto = lib.mkOption { type = lib.types.port; };
  };

  config = lib.mkIf config.ai.opendesign.enable {
    assertions = [{
      assertion = config.sops.enable;
      message = "opendesign requiere sops para OD_API_TOKEN";
    }];

    services.open-design = {
      enable    = true;
      autoStart = true;
      port      = config.ai.opendesign.puerto;
      environmentFile = config.sops.secrets."opendesign/env".path;
    };

    systemd.services.open-design.environment.PATH = lib.mkForce
      "/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin";

    sops.secrets."opendesign/env" = {};

    environment.persistence."/persist".users.${config.usuarioPrincipal} =
      lib.mkIf (config.impermanencia.enable) {
        directories = [{ directory = ".open-design" ; mode = "0750"; }];
      };
  };
}
