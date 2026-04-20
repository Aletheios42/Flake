# modules/apps/fzf.nix
{ pkgs, ... }:
{
  userPackages.fzf = [
    (pkgs.symlinkJoin {
      name = "fzf";
      paths = [ pkgs.fzf ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/fzf \
          --set FZF_DEFAULT_COMMAND "rg --files --hidden --smart-case"
      '';
    })
    pkgs.ripgrep
  ];
}
