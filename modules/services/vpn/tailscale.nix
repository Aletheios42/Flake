{ lib, config, ... }: {
  options.vpn.tailscale.enable = lib.mkEnableOption "Activa tailscale";

  config = lib.mkIf config.vpn.tailscale.enable {
    assertions = [{
      assertion = config.sops.enable;
      message = "vpn.tailscale requiere sops (sops.enable) para la clave de autenticación";
    }];

    sops.secrets."tailscale/apikey" = {};

    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/apikey".path;
      extraUpFlags = [ "--accept-routes" ];
      useRoutingFeatures = "client";
    };

    systemd.services.tailscaled.after = [ "sops-nix.service" ];

    environment.persistence."/persist" = lib.mkIf (config.impermanencia.enable) {
      directories = [{ directory = "/var/lib/tailscale" ; mode = "0750"; }];
    };
  };
}
