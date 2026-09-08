{ config, lib, ...}:
{
  system.stateVersion =  "26.05";
  nix.settings.download-buffer-size = 524288000; # 500MB
  nix.settings.experimental-features = ["nix-command" "flakes" "configurable-impure-env"];
  nixpkgs.config.allowUnfree = true;
  nix.settings = { impure-env = [ "NIXPKGS_ALLOW_UNFREE=1" ]; };
  environment.sessionVariables = { NIXPKGS_ALLOW_UNFREE = "1"; };
  nix.settings.trusted-users = [ "root" "@wheel" ];

  nix.gc = {
    automatic = true;
    dates = "weekly"; # O el intervalo que prefieras (ej. "daily")
    options = "--delete-older-than 14d";
  };
}
