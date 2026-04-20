# modules/apps/kitty.nix
{ pkgs, ... }:
{
  userPackages.kitty = [
    (pkgs.symlinkJoin {
      name = "kitty";
      paths = [ pkgs.kitty ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/kitty \
          --add-flags "--config ${pkgs.writeText "kitty.conf" ''
            enable_audio_bell no
          ''}"
      '';
    })
  ];
}
