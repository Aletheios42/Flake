{...}:
{
  system.stateVersion = "25.11";
  nix.settings.download-buffer-size = 524288000; # 500MB
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;
  i18n.defaultLocale = "es_ES.UTF-8";
  documentation = {
    enable = true;
    man.enable = true;
    man.cache.enable = true;      # genera whatis db, acelera apropos
    info.enable = true;           # páginas GNU info
    nixos.enable = true;          # nixos-help y opciones locales
    doc.enable = true;            # HTML docs de paquetes
  };
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enableZshIntegration = true;

}
