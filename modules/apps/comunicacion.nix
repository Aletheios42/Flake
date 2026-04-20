{ pkgs, ... }:
{
  userPackages.comunicacion =  [
    pkgs.webcord pkgs.whatsie pkgs.slack pkgs.telegram-desktop pkgs.thunderbird

  ];
}
