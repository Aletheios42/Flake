# modules/apps/git.nix
{ pkgs, ... }:
let
  gitConf = pkgs.writeText "gitconfig" ''
    [user]
      name = aletheios42
      email = 
    [init]
      defaultBranch = master
    [credential]
      helper = store
  '';
in
{
  userPackages.git = [
    (pkgs.symlinkJoin {
      name = "git";
      paths = [ pkgs.git ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/git \
          --add-flags "-c include.path=${gitConf}"
      '';
    })
  ];
}
