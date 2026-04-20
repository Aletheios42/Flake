# modules/apps/ranger.nix
{ pkgs, ... }:
let
  rangerConf = pkgs.writeText "rc.conf" ''
    set show_hidden true
    map f shell find . -name "%s"
    set preview_images true
    set preview_images_method w3m
    map yy copy
    map dd cut
    map pp paste
  '';
in
{
  userPackages.ranger = [
    (pkgs.symlinkJoin {
      name = "ranger";
      paths = [ pkgs.ranger ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/ranger \
          --set RANGER_LOAD_DEFAULT_RC FALSE \
          --add-flags "--cmd='source ${rangerConf}'"
      '';
    })
  ];
}
