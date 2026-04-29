{ lib, config, ... }: 
{
  # open telemetry y openobserve
  # services.ntfy-sh = {
  #   enable = true;
  #   settings = {
  #     base-url = "https://ntfy.alejandropintosalcarazo.com";
  #     listen-http = ":2586";
  #     auth-default-access = "deny-all";
  #   };
  # };
  #
  # services.nginx.virtualHosts."ntfy.alejandropintosalcarazo.com" = {
  #   enableACME = true; forceSSL = true;
  #   locations."/" = {
  #     proxyPass = "http://127.0.0.1:2586";
  #     proxyWebsockets = true;
  #   };
  # };
}
