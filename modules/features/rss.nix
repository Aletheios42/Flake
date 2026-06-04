{ pkgs, config, lib, ...}:
{
  options.rss.enable = lib.mkEnableOption "Activa commafeed";

  config = lib.mkIf (config.rss.enable) {
    userPackages.rss = [ pkgs.commafeed ];
    services.commafeed.enable = true;
  };
}
